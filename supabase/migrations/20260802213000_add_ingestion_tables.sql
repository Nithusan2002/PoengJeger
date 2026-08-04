create table if not exists public.source_registry (
  id uuid primary key default gen_random_uuid(),
  campaign_source_id uuid not null unique references public.campaign_sources (id) on delete cascade,
  ingest_kind text not null,
  base_url text,
  parser_key text,
  poll_interval_minutes integer not null default 360,
  is_active boolean not null default true,
  last_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint source_registry_ingest_kind check (
    ingest_kind in ('api', 'rss', 'newsletter', 'html_page', 'manual')
  ),
  constraint source_registry_poll_interval_positive check (poll_interval_minutes > 0)
);

create table if not exists public.ingestion_runs (
  id uuid primary key default gen_random_uuid(),
  source_registry_id uuid not null references public.source_registry (id) on delete cascade,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'running',
  candidate_count integer not null default 0,
  error_message text,
  created_at timestamptz not null default now(),
  constraint ingestion_runs_status check (
    status in ('running', 'succeeded', 'failed', 'partial')
  ),
  constraint ingestion_runs_candidate_count_non_negative check (candidate_count >= 0),
  constraint ingestion_runs_finished_after_start check (
    finished_at is null or finished_at >= started_at
  )
);

create table if not exists public.ingestion_candidates (
  id uuid primary key default gen_random_uuid(),
  source_registry_id uuid not null references public.source_registry (id) on delete cascade,
  source_url text not null,
  detected_at timestamptz not null default now(),
  title text not null,
  summary text,
  raw_content text not null,
  normalized_hash text,
  suggested_program_id uuid references public.bonus_programs (id) on delete set null,
  suggested_category_id uuid references public.campaign_categories (id) on delete set null,
  status text not null default 'new',
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  promoted_campaign_id uuid references public.campaigns (id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ingestion_candidates_status check (
    status in ('new', 'needs_review', 'approved', 'rejected', 'promoted')
  ),
  constraint ingestion_candidates_review_pair check (
    (reviewed_by is null and reviewed_at is null)
    or (reviewed_by is not null and reviewed_at is not null)
  )
);

create index if not exists source_registry_active_idx
  on public.source_registry (is_active, poll_interval_minutes);

create index if not exists ingestion_runs_source_started_idx
  on public.ingestion_runs (source_registry_id, started_at desc);

create index if not exists ingestion_candidates_status_detected_idx
  on public.ingestion_candidates (status, detected_at desc);

create index if not exists ingestion_candidates_promoted_campaign_idx
  on public.ingestion_candidates (promoted_campaign_id)
  where promoted_campaign_id is not null;

create unique index if not exists ingestion_candidates_source_hash_idx
  on public.ingestion_candidates (source_registry_id, normalized_hash)
  where normalized_hash is not null;

drop trigger if exists set_source_registry_updated_at on public.source_registry;
create trigger set_source_registry_updated_at
before update on public.source_registry
for each row execute function public.set_updated_at();

drop trigger if exists set_ingestion_candidates_updated_at on public.ingestion_candidates;
create trigger set_ingestion_candidates_updated_at
before update on public.ingestion_candidates
for each row execute function public.set_updated_at();

alter table public.source_registry enable row level security;
alter table public.ingestion_runs enable row level security;
alter table public.ingestion_candidates enable row level security;

create policy "admins manage source registry"
on public.source_registry
for all
using (public.is_admin())
with check (public.is_admin());

create policy "admins manage ingestion runs"
on public.ingestion_runs
for all
using (public.is_admin())
with check (public.is_admin());

create policy "admins manage ingestion candidates"
on public.ingestion_candidates
for all
using (public.is_admin())
with check (public.is_admin());
