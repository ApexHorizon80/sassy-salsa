create table public.site_content (
  key text primary key,
  value text not null default '',
  updated_at timestamptz not null default now()
);
alter table public.site_content enable row level security;
create policy "Anyone can read site content" on public.site_content for select using (true);
create policy "Admins can update site content" on public.site_content for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins can insert site content" on public.site_content for insert to authenticated with check (public.is_admin());
grant select on public.site_content to anon, authenticated;
grant insert, update on public.site_content to authenticated;
insert into public.site_content (key, value) values
('announcement', 'Free local pickup on orders $35+ · Small batch, made with love'),
('hero_eyebrow', 'Sassy by name. Saucy by nature.'),
('hero_title', 'Made for good company.'),
('hero_description', 'Small-batch salsa with big personality. Four bright, chunky flavors made for dipping, drizzling, and passing around.'),
('story_eyebrow', 'A little bit of sass'),
('story_title', 'Recipes worth gathering for.'),
('story_body', 'We started Sassy Salsa because the best nights always seem to happen around a good bowl of salsa. So we make ours the old-fashioned way: bright produce, bold spices, and a whole lot of tasting.'),
('callout_title', 'Good news. We do express.'),
('callout_body', 'Order online, choose local pickup, and we will have your salsa ready in as little as 2 hours.')
on conflict (key) do nothing;
