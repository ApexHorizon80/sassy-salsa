create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  event_type text not null check (event_type in ('ORDER_CREATED','ORDER_CONFIRMED','ORDER_PREPARING','ORDER_READY','ORDER_COMPLETED','ORDER_CANCELLED','EXPRESS_ORDER_CREATED','PREORDER_CREATED')),
  title text not null,
  message text not null,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique (order_id, event_type)
);
create index notifications_user_created_idx on public.notifications(user_id, created_at desc);
alter table public.notifications enable row level security;
create policy "Customers can read own notifications" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "Customers can mark own notifications read" on public.notifications for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Admins can inspect notifications" on public.notifications for select to authenticated using (public.is_admin());
revoke insert, delete on public.notifications from anon, authenticated;
revoke update on public.notifications from anon, authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

create or replace function public.create_order_notification() returns trigger language plpgsql security definer set search_path = public as $$
declare v_event text; v_title text; v_message text; v_user uuid := new.user_id;
begin
  if tg_op = 'INSERT' then
    v_event := 'ORDER_CREATED'; v_title := 'Order received'; v_message := 'Order ' || new.order_number || ' was created.';
    insert into public.notifications(user_id, order_id, event_type, title, message) values (v_user, new.id, v_event, v_title, v_message) on conflict (order_id,event_type) do nothing;
    if new.order_type = 'express' then v_event := 'EXPRESS_ORDER_CREATED'; v_title := 'Express order received'; v_message := 'Express order ' || new.order_number || ' was created.'; elsif new.order_type = 'preorder' then v_event := 'PREORDER_CREATED'; v_title := 'Pre-order received'; v_message := 'Pre-order ' || new.order_number || ' was created.'; else return new; end if;
    insert into public.notifications(user_id, order_id, event_type, title, message) values (v_user, new.id, v_event, v_title, v_message) on conflict (order_id,event_type) do nothing;
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    v_event := case new.status when 'confirmed' then 'ORDER_CONFIRMED' when 'preparing' then 'ORDER_PREPARING' when 'ready' then 'ORDER_READY' when 'completed' then 'ORDER_COMPLETED' when 'cancelled' then 'ORDER_CANCELLED' else null end;
    if v_event is null then return new; end if;
    v_title := case v_event when 'ORDER_CONFIRMED' then 'Order confirmed' when 'ORDER_PREPARING' then 'Order being prepared' when 'ORDER_READY' then 'Order ready for pickup' when 'ORDER_COMPLETED' then 'Order completed' else 'Order cancelled' end;
    v_message := case v_event when 'ORDER_CONFIRMED' then 'Order ' || new.order_number || ' was confirmed.' when 'ORDER_PREPARING' then 'Order ' || new.order_number || ' is being prepared.' when 'ORDER_READY' then 'Order ' || new.order_number || ' is ready for pickup.' when 'ORDER_COMPLETED' then 'Order ' || new.order_number || ' has been completed.' else 'Order ' || new.order_number || ' was cancelled.' end;
    insert into public.notifications(user_id, order_id, event_type, title, message) values (v_user, new.id, v_event, v_title, v_message) on conflict (order_id,event_type) do nothing;
  end if;
  return new;
end;
$$;
revoke all on function public.create_order_notification() from public, anon, authenticated;

create trigger orders_notification_after_insert after insert on public.orders for each row execute function public.create_order_notification();
create trigger orders_notification_after_status_update after update of status on public.orders for each row execute function public.create_order_notification();
