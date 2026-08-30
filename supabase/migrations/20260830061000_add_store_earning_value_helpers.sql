create or replace function public.extract_first_decimal(p_text text)
returns numeric
language sql
immutable
set search_path = public
as $$
  select nullif(
    replace(
      substring(coalesce(p_text, '') from '[0-9]+([,.][0-9]+)?'),
      ',',
      '.'
    ),
    ''
  )::numeric;
$$;

create or replace function public.format_norwegian_decimal(
  p_value numeric,
  p_scale integer default 2
)
returns text
language sql
immutable
set search_path = public
as $$
  select regexp_replace(
    replace(
      to_char(
        round(p_value, greatest(0, p_scale)),
        'FM999999990D' || repeat('0', greatest(0, p_scale))
      ),
      '.',
      ','
    ),
    ',?0+$',
    ''
  );
$$;
