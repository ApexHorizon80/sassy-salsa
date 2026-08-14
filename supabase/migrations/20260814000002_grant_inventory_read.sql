grant select on public.inventory to anon, authenticated;
create policy "Anyone can read inventory quantities" on public.inventory for select using (true);
