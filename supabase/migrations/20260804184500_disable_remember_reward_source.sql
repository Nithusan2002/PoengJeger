update public.source_registry
set
  is_active = false,
  updated_at = now()
where parser_key = 'remember_reward';
