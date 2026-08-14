create extension if not exists pgcrypto;

create table public.products (
  id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
  description text not null default '', image_url text not null default '', price numeric(10,2) not null check (price >= 0),
  jar_size text not null, heat_level text not null, is_active boolean not null default true,
  preorder_enabled boolean not null default false, preorder_available_date date, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.inventory (
  id uuid primary key default gen_random_uuid(), product_id uuid not null unique references public.products(id) on delete cascade,
  quantity integer not null default 0 check (quantity >= 0), low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0), updated_at timestamptz not null default now()
);
create type public.order_type as enum ('pickup','delivery'); create type public.order_status as enum ('pending','confirmed','ready','completed','cancelled');
create table public.orders (id uuid primary key default gen_random_uuid(), order_number text not null unique, customer_id uuid, order_type public.order_type not null, status public.order_status not null default 'pending', subtotal numeric(10,2) not null check (subtotal >= 0), delivery_fee numeric(10,2) not null default 0 check (delivery_fee >= 0), total numeric(10,2) not null check (total >= 0), notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.order_items (id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, product_id uuid not null references public.products(id), product_name text not null, quantity integer not null check (quantity > 0), unit_price numeric(10,2) not null check (unit_price >= 0), subtotal numeric(10,2) not null check (subtotal >= 0), created_at timestamptz not null default now());
create table public.pre_orders (id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, product_id uuid not null references public.products(id), quantity integer not null check (quantity > 0), expected_available_date date not null, status text not null default 'pending', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.order_status_history (id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, old_status public.order_status, new_status public.order_status not null, changed_at timestamptz not null default now());
create index products_active_idx on public.products(is_active); create index inventory_product_idx on public.inventory(product_id); create index order_items_order_idx on public.order_items(order_id); create index orders_customer_idx on public.orders(customer_id);
alter table public.products enable row level security; alter table public.inventory enable row level security; alter table public.orders enable row level security; alter table public.order_items enable row level security; alter table public.pre_orders enable row level security; alter table public.order_status_history enable row level security;
create policy "Anyone can read active products" on public.products for select using (is_active = true);
create policy "No public inventory access" on public.inventory for all using (false) with check (false);
create policy "No public order access" on public.orders for all using (false) with check (false);
create policy "No public order item access" on public.order_items for all using (false) with check (false);
create policy "No public preorder access" on public.pre_orders for all using (false) with check (false);
create policy "No public status history access" on public.order_status_history for all using (false) with check (false);
