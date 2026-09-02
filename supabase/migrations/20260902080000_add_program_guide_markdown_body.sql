alter table public.program_guides
  add column if not exists body_markdown text;

alter table public.program_guides
  drop constraint if exists program_guides_published_strategy_present;

alter table public.program_guides
  drop constraint if exists program_guides_earning_tips_present;

alter table public.program_guides
  drop constraint if exists program_guides_redemption_tips_present;

alter table public.program_guides
  drop constraint if exists program_guides_risk_notes_present;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'program_guides_published_content_present'
      and conrelid = 'public.program_guides'::regclass
  ) then
    alter table public.program_guides
      add constraint program_guides_published_content_present check (
        status <> 'published'
        or length(trim(coalesce(body_markdown, ''))) > 0
        or (
          length(trim(coalesce(strategy, ''))) > 0
          and array_length(earning_tips, 1) is not null
          and array_length(redemption_tips, 1) is not null
          and array_length(risk_notes, 1) is not null
        )
      );
  end if;
end $$;
