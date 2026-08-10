create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_editorial_role() in ('admin', 'editor'), false);
$$;

revoke execute on function public.current_editorial_role() from public;
revoke execute on function public.current_editorial_role() from anon;
grant execute on function public.current_editorial_role() to authenticated;
grant execute on function public.current_editorial_role() to service_role;

grant execute on function public.is_admin() to anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_admin() to service_role;
