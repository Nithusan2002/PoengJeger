create table public.launch_waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  consent_version text not null,
  source text not null,
  consented_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint launch_waitlist_email_normalized check (email = lower(btrim(email))),
  constraint launch_waitlist_email_length check (char_length(email) between 3 and 254),
  constraint launch_waitlist_email_shape check (email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
  constraint launch_waitlist_consent_version_check check (consent_version = '2026-09-14'),
  constraint launch_waitlist_source_check check (source = 'nithusan.no/poengjeger')
);

create unique index launch_waitlist_email_unique_idx
  on public.launch_waitlist (email);

alter table public.launch_waitlist enable row level security;

revoke all on public.launch_waitlist from anon, authenticated;

comment on table public.launch_waitlist is
  'Email addresses submitted with explicit consent for one Poengjeger pilot or launch notification.';
comment on column public.launch_waitlist.consent_version is
  'Version date of the privacy copy accepted at submission time.';
