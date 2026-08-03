create or replace function public.current_editorial_role()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  resolved_role text;
begin
  if auth.role() = 'service_role' then
    return 'admin';
  end if;

  select eur.role
    into resolved_role
  from public.editorial_user_roles eur
  where eur.user_id = auth.uid()
    and eur.revoked_at is null
  limit 1;

  if resolved_role is not null then
    return resolved_role;
  end if;

  return auth.jwt() -> 'app_metadata' ->> 'poengjeger_role';
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select coalesce(public.current_editorial_role() in ('admin', 'editor'), false);
$$;
