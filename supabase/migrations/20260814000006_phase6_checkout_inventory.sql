alter table public.orders add column if not exists client_request_id uuid;
create unique index if not exists orders_user_request_idx on public.orders(user_id, client_request_id) where client_request_id is not null;
create sequence if not exists public.order_number_seq start 1;

drop function if exists public.create_customer_order(text,date,text,jsonb);
create or replace function public.create_customer_order(p_order_type text, p_requested_date date, p_customer_notes text, p_items jsonb, p_client_request_id uuid) returns uuid language plpgsql security definer set search_path = public as $$
declare v_user uuid := auth.uid(); v_order_id uuid; v_number text; v_total numeric(10,2) := 0; v_item jsonb; v_product public.products%rowtype; v_qty integer; v_inventory public.inventory%rowtype; v_is_preorder boolean := p_order_type = 'preorder';
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_client_request_id is null then raise exception 'Request identifier required'; end if;
  select id into v_order_id from public.orders where user_id = v_user and client_request_id = p_client_request_id;
  if found then return v_order_id; end if;
  if p_order_type not in ('normal','express','preorder') then raise exception 'Invalid order type'; end if;
  if v_is_preorder and p_requested_date is null then raise exception 'A requested date is required for pre-orders'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'At least one item is required'; end if;
  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and is_active = true;
    if not found then raise exception 'Product is inactive or unavailable'; end if;
    v_qty := (v_item->>'quantity')::integer;
    if v_qty is null or v_qty <= 0 then raise exception 'Quantity must be positive'; end if;
    if v_is_preorder then
      if not v_product.preorder_enabled then raise exception 'Product is not available for preorder'; end if;
    else
      select * into v_inventory from public.inventory where product_id = v_product.id for update;
      if not found or v_inventory.quantity < v_qty then raise exception 'Insufficient inventory for %', v_product.name; end if;
    end if;
    v_total := v_total + (v_product.price * v_qty);
  end loop;
  v_number := 'SS-' || lpad(nextval('public.order_number_seq')::text, 6, '0');
  insert into public.orders(user_id, customer_id, client_request_id, order_number, order_type, status, customer_notes, notes, total_amount, subtotal, total, requested_date) values (v_user, v_user, p_client_request_id, v_number, p_order_type, 'pending', p_customer_notes, p_customer_notes, v_total, v_total, v_total, p_requested_date) returning id into v_order_id;
  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;
    insert into public.order_items(order_id, product_id, product_name, quantity, unit_price, subtotal) values (v_order_id, v_product.id, v_product.name, v_qty, v_product.price, v_product.price * v_qty);
    if not v_is_preorder then update public.inventory set quantity = quantity - v_qty, updated_at = now() where product_id = v_product.id; end if;
  end loop;
  return v_order_id;
end;
$$;
revoke all on function public.create_customer_order(text,date,text,jsonb,uuid) from public, anon;
grant execute on function public.create_customer_order(text,date,text,jsonb,uuid) to authenticated;
