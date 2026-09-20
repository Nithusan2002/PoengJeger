begin;

-- Keep the privilege-bypassing lookup outside the Data API's exposed schema.
-- Public wrappers retain their existing signatures so the admin tool, Edge
-- Functions and RLS policies do not need to change.
create schema if not exists private;

revoke all on schema private from public;
grant usage on schema private to anon, authenticated, service_role;

create or replace function private.current_editorial_role()
returns text
language plpgsql
stable
security definer
set search_path = pg_catalog
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

revoke all on function private.current_editorial_role() from public;
grant execute on function private.current_editorial_role() to anon, authenticated, service_role;

create or replace function public.current_editorial_role()
returns text
language sql
stable
security invoker
set search_path = pg_catalog
as $$
  select private.current_editorial_role();
$$;

create or replace function public.is_editorial_member()
returns boolean
language sql
stable
security invoker
set search_path = pg_catalog
as $$
  select coalesce(private.current_editorial_role() in ('admin', 'editor'), false);
$$;

create or replace function public.is_admin_role()
returns boolean
language sql
stable
security invoker
set search_path = pg_catalog
as $$
  select coalesce(private.current_editorial_role() = 'admin', false);
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security invoker
set search_path = pg_catalog
as $$
  select coalesce(private.current_editorial_role() in ('admin', 'editor'), false);
$$;

revoke all on function public.current_editorial_role() from public, anon;
grant execute on function public.current_editorial_role() to authenticated, service_role;

revoke all on function public.is_editorial_member() from public;
grant execute on function public.is_editorial_member() to anon, authenticated, service_role;

revoke all on function public.is_admin_role() from public;
grant execute on function public.is_admin_role() to anon, authenticated, service_role;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated, service_role;

alter function public.grant_editorial_role(uuid, text, text)
  set search_path = pg_catalog, public;

alter function public.revoke_editorial_role(uuid, text)
  set search_path = pg_catalog, public;

alter function public.product_event_properties_are_safe(jsonb)
  set search_path = pg_catalog;

alter function public.validate_product_event()
  set search_path = pg_catalog, public;

drop policy if exists "clients insert product events" on public.product_events;
create policy "clients insert validated product events"
on public.product_events
for insert
to anon, authenticated
with check (
  occurred_at <= now() + interval '5 minutes'
  and occurred_at >= now() - interval '30 days'
  and public.product_event_properties_are_safe(properties)
);

commit;
