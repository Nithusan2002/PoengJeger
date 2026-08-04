create table if not exists public.editorial_user_roles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null,
  granted_by uuid references auth.users (id) on delete set null,
  grant_note text,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint editorial_user_roles_role check (role in ('editor', 'admin')),
  constraint editorial_user_roles_revoked_after_granted check (
    revoked_at is null or revoked_at >= granted_at
  )
);

create index if not exists editorial_user_roles_role_active_idx
  on public.editorial_user_roles (role, user_id)
  where revoked_at is null;

drop trigger if exists set_editorial_user_roles_updated_at on public.editorial_user_roles;
create trigger set_editorial_user_roles_updated_at
before update on public.editorial_user_roles
for each row execute function public.set_updated_at();

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
  if current_user in ('postgres', 'service_role', 'supabase_admin') then
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

create or replace function public.grant_editorial_role(
  p_user_id uuid,
  p_role text,
  p_grant_note text default null
)
returns public.editorial_user_roles
language plpgsql
security invoker
as $$
declare
  role_record public.editorial_user_roles;
begin
  if not (
    public.current_editorial_role() = 'admin'
    or current_user in ('postgres', 'service_role', 'supabase_admin')
  ) then
    raise exception 'Only admins can grant editorial roles';
  end if;

  if p_role not in ('editor', 'admin') then
    raise exception 'Unsupported editorial role: %', p_role;
  end if;

  insert into public.editorial_user_roles (
    user_id,
    role,
    granted_by,
    grant_note,
    granted_at,
    revoked_at
  )
  values (
    p_user_id,
    p_role,
    auth.uid(),
    p_grant_note,
    now(),
    null
  )
  on conflict (user_id) do update
  set
    role = excluded.role,
    granted_by = excluded.granted_by,
    grant_note = excluded.grant_note,
    granted_at = excluded.granted_at,
    revoked_at = null
  returning * into role_record;

  return role_record;
end;
$$;

create or replace function public.revoke_editorial_role(
  p_user_id uuid,
  p_revoke_note text default null
)
returns public.editorial_user_roles
language plpgsql
security invoker
as $$
declare
  role_record public.editorial_user_roles;
begin
  if not (
    public.current_editorial_role() = 'admin'
    or current_user in ('postgres', 'service_role', 'supabase_admin')
  ) then
    raise exception 'Only admins can revoke editorial roles';
  end if;

  update public.editorial_user_roles
  set
    revoked_at = now(),
    grant_note = coalesce(
      nullif(trim(p_revoke_note), ''),
      grant_note
    )
  where user_id = p_user_id
    and revoked_at is null
  returning * into role_record;

  if role_record.user_id is null then
    raise exception 'No active editorial role found for user %', p_user_id;
  end if;

  return role_record;
end;
$$;

alter table public.editorial_user_roles enable row level security;

drop policy if exists "admins read editorial roles" on public.editorial_user_roles;
create policy "admins read editorial roles"
on public.editorial_user_roles
for select
using (public.is_admin());

drop policy if exists "admins manage editorial roles" on public.editorial_user_roles;
create policy "admins manage editorial roles"
on public.editorial_user_roles
for all
using (public.current_editorial_role() = 'admin')
with check (public.current_editorial_role() = 'admin');
