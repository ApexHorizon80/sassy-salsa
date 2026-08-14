create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin')),
  created_at timestamptz not null default now()
);
alter table public.order_status_history alter column old_status type text using old_status::text;
alter table public.order_status_history alter column new_status type text using new_status::text;
alter table public.user_roles enable row level security;

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin');
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
grant select on public.user_roles to authenticated;
create policy "Admins can read roles" on public.user_roles for select to authenticated using (public.is_admin());

create policy "Admins can read all profiles" on public.customer_profiles for select to authenticated using (public.is_admin());
create policy "Admins can read all orders" on public.orders for select to authenticated using (public.is_admin());
create policy "Admins can update orders" on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins can read all order items" on public.order_items for select to authenticated using (public.is_admin());
create policy "Admins can read all products" on public.products for select to authenticated using (public.is_admin());
create policy "Admins can update products" on public.products for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins can update inventory" on public.inventory for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins can read inventory" on public.inventory for select to authenticated using (public.is_admin());

create or replace function public.admin_update_order_status(p_order_id uuid, p_status text) returns public.orders language plpgsql security definer set search_path = public as $$
declare v_order public.orders;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_status not in ('pending','confirmed','preparing','ready','completed','cancelled') then raise exception 'Invalid order status'; end if;
  update public.orders set status = p_status, ready_at = case when p_status = 'ready' then coalesce(ready_at, now()) else ready_at end, updated_at = now() where id = p_order_id returning * into v_order;
  if not found then raise exception 'Order not found'; end if;
  insert into public.order_status_history(order_id, old_status, new_status) values (v_order.id, null, p_status);
  return v_order;
end;
$$;
revoke all on function public.admin_update_order_status(uuid,text) from public, anon;
grant execute on function public.admin_update_order_status(uuid,text) to authenticated;

grant select on public.products, public.inventory, public.orders, public.order_items, public.customer_profiles to authenticated;
