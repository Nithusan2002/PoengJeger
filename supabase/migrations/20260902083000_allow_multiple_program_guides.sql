alter table public.program_guides
  add column if not exists title text;

update public.program_guides guide
set title = coalesce(
  nullif(trim(title), ''),
  concat('Slik fungerer ', program.name)
)
from public.bonus_programs program
where program.id = guide.program_id;

alter table public.program_guides
  drop constraint if exists program_guides_program_id_key;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'program_guides_published_title_present'
      and conrelid = 'public.program_guides'::regclass
  ) then
    alter table public.program_guides
      add constraint program_guides_published_title_present check (
        status <> 'published' or length(trim(coalesce(title, ''))) > 0
      );
  end if;
end $$;

create index if not exists program_guides_status_program_updated_idx
  on public.program_guides (status, program_id, updated_at desc);
