create or replace function public.extract_first_decimal(p_text text)
returns numeric
language sql
immutable
set search_path = public
as $$
  select nullif(
    replace(
      substring(coalesce(p_text, '') from '[0-9]+[,.]?[0-9]*'),
      ',',
      '.'
    ),
    ''
  )::numeric;
$$;
