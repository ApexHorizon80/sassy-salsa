create policy "Admins can create products" on public.products for insert to authenticated with check (public.is_admin());
create policy "Admins can create inventory" on public.inventory for insert to authenticated with check (public.is_admin());
