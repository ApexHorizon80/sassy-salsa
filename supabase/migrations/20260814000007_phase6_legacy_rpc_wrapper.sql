create or replace function public.create_customer_order(p_order_type text, p_requested_date date, p_customer_notes text, p_items jsonb) returns uuid language sql security definer set search_path = public as $$
  select public.create_customer_order(p_order_type, p_requested_date, p_customer_notes, p_items, gen_random_uuid());
$$;
revoke all on function public.create_customer_order(text,date,text,jsonb) from public, anon;
grant execute on function public.create_customer_order(text,date,text,jsonb) to authenticated;
