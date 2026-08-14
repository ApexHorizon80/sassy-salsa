create or replace function public.grant_admin_role(p_user_id uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_roles(user_id, role) values (p_user_id, 'admin') on conflict (user_id) do update set role = 'admin';
end;
$$;
revoke all on function public.grant_admin_role(uuid) from public, anon, authenticated;
grant execute on function public.grant_admin_role(uuid) to service_role;
