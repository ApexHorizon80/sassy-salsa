insert into public.products (name, slug, description, price, jar_size, heat_level, is_active, preorder_enabled)
values
('Green Salsa','green-salsa','Development placeholder description.',10,'16 oz jar','Mild / Medium',true,false),
('Red Salsa','red-salsa','Development placeholder description.',10,'16 oz jar','Medium',true,false),
('Verde Salsa','verde-salsa','Development placeholder description.',11,'16 oz jar','Medium / Hot',true,false),
('Habanero Salsa','habanero-salsa','Development placeholder description.',12,'16 oz jar','Hot',true,false)
on conflict (slug) do update set updated_at = now();
insert into public.inventory (product_id, quantity, low_stock_threshold)
select id, 20, 5 from public.products where slug in ('green-salsa','red-salsa','verde-salsa','habanero-salsa')
on conflict (product_id) do update set quantity = excluded.quantity, updated_at = now();
