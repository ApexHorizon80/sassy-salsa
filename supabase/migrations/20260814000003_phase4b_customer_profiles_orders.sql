create table public.customer_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '', email text not null default '', phone text, address text, city text, state text, postal_code text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.orders add column if not exists customer_notes text;
alter table public.orders add column if not exists total_amount numeric(10,2);
alter table public.orders add column if not exists requested_date date;
alter table public.orders add column if not exists ready_at timestamptz;
alter table public.orders alter column order_type drop default;
alter table public.orders alter column order_type type text using order_type::text;
alter table public.orders add constraint orders_order_type_check check (order_type in ('normal','express','preorder'));
alter table public.orders alter column status drop default;
alter table public.orders alter column status type text using status::text;
alter table public.orders add constraint orders_status_check check (status in ('pending','confirmed','preparing','ready','completed','cancelled'));
alter table public.order_items add column if not exists unit_price numeric(10,2);
alter table public.order_items add constraint order_items_unit_price_nonnegative check (unit_price >= 0);
create index if not exists orders_user_idx on public.orders(user_id);
create index if not exists profiles_email_idx on public.customer_profiles(email);

alter table public.customer_profiles enable row level security;
create policy "Customers can read own profile" on public.customer_profiles for select to authenticated using (user_id = auth.uid());
create policy "Customers can insert own profile" on public.customer_profiles for insert to authenticated with check (user_id = auth.uid());
create policy "Customers can update own profile" on public.customer_profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "No public order access" on public.orders;
create policy "Customers can read own orders" on public.orders for select to authenticated using (user_id = auth.uid());
drop policy if exists "No public order item access" on public.order_items;
create policy "Customers can read own order items" on public.order_items for select to authenticated using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));

create or replace function public.handle_new_customer_profile() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.customer_profiles(user_id, full_name, email) values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), coalesce(new.email,'')) on conflict (user_id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users for each row execute procedure public.handle_new_customer_profile();

create or replace function public.create_customer_order(p_order_type text, p_requested_date date, p_customer_notes text, p_items jsonb) returns uuid language plpgsql security definer set search_path = public as $$
declare v_user uuid := auth.uid(); v_order_id uuid; v_number text; v_total numeric(10,2) := 0; v_item jsonb; v_product public.products%rowtype; v_qty integer; v_price numeric(10,2);
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_order_type not in ('normal','express','preorder') then raise exception 'Invalid order type'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'At least one item is required'; end if;
  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and is_active = true;
    if not found then raise exception 'Product is inactive or unavailable'; end if;
    v_qty := (v_item->>'quantity')::integer;
    if v_qty is null or v_qty <= 0 then raise exception 'Quantity must be positive'; end if;
    if p_order_type = 'preorder' and not v_product.preorder_enabled then raise exception 'Product is not available for preorder'; end if;
    v_price := v_product.price; v_total := v_total + (v_price * v_qty);
  end loop;
  v_number := 'SS-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
  insert into public.orders(user_id, customer_id, order_number, order_type, status, customer_notes, notes, total_amount, subtotal, total, requested_date) values (v_user, v_user, v_number, p_order_type, 'pending', p_customer_notes, p_customer_notes, v_total, v_total, v_total, p_requested_date) returning id into v_order_id;
  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;
    insert into public.order_items(order_id, product_id, product_name, quantity, unit_price, subtotal) values (v_order_id, v_product.id, v_product.name, v_qty, v_product.price, v_product.price * v_qty);
  end loop;
  return v_order_id;
end;
$$;
revoke all on function public.create_customer_order(text,date,text,jsonb) from public, anon;
grant execute on function public.create_customer_order(text,date,text,jsonb) to authenticated;
grant select, insert, update on public.customer_profiles to authenticated;
grant select on public.orders, public.order_items to authenticated;
