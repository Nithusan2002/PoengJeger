create or replace function public.extract_first_decimal(p_text text)
returns numeric
language sql
immutable
set search_path = public
as $$
  with extracted as (
    select substring(
      coalesce(p_text, '')
      from '[0-9][0-9[:space:]]*[,.]?[0-9]*'
    ) as value
  )
  select nullif(
    replace(
      regexp_replace(coalesce(value, ''), '[[:space:]]', '', 'g'),
      ',',
      '.'
    ),
    ''
  )::numeric
  from extracted;
$$;
