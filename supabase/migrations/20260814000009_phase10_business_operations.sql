create table if not exists public.store_settings (
  id boolean primary key default true check (id = true),
  is_open boolean not null default true,
  updated_at timestamptz not null default now()
);
insert into public.store_settings(id, is_open) values (true, true) on conflict (id) do nothing;
alter table public.store_settings enable row level security;
create policy "Anyone can read store availability" on public.store_settings for select using (true);
create policy "Admins can update store availability" on public.store_settings for update to authenticated using (public.is_admin()) with check (public.is_admin());
grant select on public.store_settings to anon, authenticated;
grant update on public.store_settings to authenticated;

alter table public.orders add column if not exists internal_notes text;
revoke select (internal_notes) on public.orders from anon, authenticated;

create or replace function public.admin_set_store_open(p_is_open boolean) returns public.store_settings language plpgsql security definer set search_path = public as $$
declare v_setting public.store_settings;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  update public.store_settings set is_open = p_is_open, updated_at = now() where id = true returning * into v_setting;
  return v_setting;
end;
$$;
revoke all on function public.admin_set_store_open(boolean) from public, anon;
grant execute on function public.admin_set_store_open(boolean) to authenticated;

create or replace function public.admin_update_order_internal_note(p_order_id uuid, p_note text) returns public.orders language plpgsql security definer set search_path = public as $$
declare v_order public.orders;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  update public.orders set internal_notes = nullif(trim(p_note), ''), updated_at = now() where id = p_order_id returning * into v_order;
  if not found then raise exception 'Order not found'; end if;
  return v_order;
end;
$$;
revoke all on function public.admin_update_order_internal_note(uuid,text) from public, anon;
grant execute on function public.admin_update_order_internal_note(uuid,text) to authenticated;

create or replace function public.admin_adjust_inventory(p_product_id uuid, p_quantity integer, p_low_stock_threshold integer) returns public.inventory language plpgsql security definer set search_path = public as $$
declare v_inventory public.inventory;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_quantity < 0 or p_low_stock_threshold < 0 then raise exception 'Inventory values cannot be negative'; end if;
  update public.inventory set quantity = p_quantity, low_stock_threshold = p_low_stock_threshold, updated_at = now() where product_id = p_product_id returning * into v_inventory;
  if not found then raise exception 'Inventory record not found'; end if;
  return v_inventory;
end;
$$;
revoke all on function public.admin_adjust_inventory(uuid,integer,integer) from public, anon;
grant execute on function public.admin_adjust_inventory(uuid,integer,integer) to authenticated;

create or replace function public.create_customer_order(p_order_type text, p_requested_date date, p_customer_notes text, p_items jsonb, p_client_request_id uuid) returns uuid language plpgsql security definer set search_path = public as $$
declare v_user uuid := auth.uid(); v_order_id uuid; v_number text; v_total numeric(10,2) := 0; v_item jsonb; v_product public.products%rowtype; v_qty integer; v_inventory public.inventory%rowtype; v_is_preorder boolean := p_order_type = 'preorder';
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.store_settings where id = true and is_open) then raise exception 'Ordering is currently closed'; end if;
  if p_client_request_id is null then raise exception 'Request identifier required'; end if;
  select id into v_order_id from public.orders where user_id = v_user and client_request_id = p_client_request_id;
  if found then return v_order_id; end if;
  if p_order_type not in ('normal','express','preorder') then raise exception 'Invalid order type'; end if;
  if v_is_preorder and p_requested_date is null then raise exception 'A requested date is required for pre-orders'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'At least one item is required'; end if;
  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and is_active = true;
    if not found then raise exception 'Product is inactive or unavailable'; end if;
    v_qty := (v_item->>'quantity')::integer; if v_qty is null or v_qty <= 0 then raise exception 'Quantity must be positive'; end if;
    if v_is_preorder then if not v_product.preorder_enabled then raise exception 'Product is not available for preorder'; end if; else select * into v_inventory from public.inventory where product_id = v_product.id for update; if not found or v_inventory.quantity < v_qty then raise exception 'Insufficient inventory for %', v_product.name; end if; end if;
    v_total := v_total + (v_product.price * v_qty);
  end loop;
  v_number := 'SS-' || lpad(nextval('public.order_number_seq')::text, 6, '0');
  insert into public.orders(user_id, customer_id, client_request_id, order_number, order_type, status, customer_notes, notes, total_amount, subtotal, total, requested_date) values (v_user, v_user, p_client_request_id, v_number, p_order_type, 'pending', p_customer_notes, p_customer_notes, v_total, v_total, v_total, p_requested_date) returning id into v_order_id;
  for v_item in select * from jsonb_array_elements(p_items) loop select * into v_product from public.products where id = (v_item->>'product_id')::uuid; v_qty := (v_item->>'quantity')::integer; insert into public.order_items(order_id, product_id, product_name, quantity, unit_price, subtotal) values (v_order_id, v_product.id, v_product.name, v_qty, v_product.price, v_product.price * v_qty); if not v_is_preorder then update public.inventory set quantity = quantity - v_qty, updated_at = now() where product_id = v_product.id; end if; end loop;
  return v_order_id;
end;
$$;
