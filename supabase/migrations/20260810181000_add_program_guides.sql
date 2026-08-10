create table if not exists public.program_guides (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null unique references public.bonus_programs (id) on delete cascade,
  status text not null default 'draft',
  strategy text not null,
  earning_tips text[] not null default '{}',
  redemption_tips text[] not null default '{}',
  risk_notes text[] not null default '{}',
  last_reviewed_at timestamptz,
  created_by uuid references auth.users (id) on delete set null,
  updated_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint program_guides_status check (status in ('draft', 'published', 'archived')),
  constraint program_guides_strategy_present check (length(trim(strategy)) > 0),
  constraint program_guides_earning_tips_present check (
    status <> 'published' or array_length(earning_tips, 1) is not null
  ),
  constraint program_guides_redemption_tips_present check (
    status <> 'published' or array_length(redemption_tips, 1) is not null
  ),
  constraint program_guides_risk_notes_present check (
    status <> 'published' or array_length(risk_notes, 1) is not null
  )
);

create index if not exists program_guides_status_program_idx
  on public.program_guides (status, program_id);

drop trigger if exists set_program_guides_updated_at on public.program_guides;
create trigger set_program_guides_updated_at
before update on public.program_guides
for each row execute function public.set_updated_at();

alter table public.program_guides enable row level security;

create policy "published program guides are readable"
on public.program_guides
for select
using (
  public.is_admin()
  or (
    status = 'published'
    and exists (
      select 1
      from public.bonus_programs bp
      where bp.id = program_guides.program_id
        and bp.is_active
    )
  )
);

create policy "admins manage program guides"
on public.program_guides
for all
using (public.is_admin())
with check (public.is_admin());
