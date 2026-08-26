alter table public.program_guides
  add column if not exists guide_kicker text,
  add column if not exists reading_time_label text,
  add column if not exists strategy_section_title text,
  add column if not exists decision_section_title text,
  add column if not exists earning_decision_label text,
  add column if not exists redemption_decision_label text,
  add column if not exists risk_decision_label text,
  add column if not exists earning_section_title text,
  add column if not exists earning_section_intro text,
  add column if not exists redemption_section_title text,
  add column if not exists redemption_section_intro text,
  add column if not exists risk_section_title text,
  add column if not exists risk_section_intro text,
  add column if not exists campaigns_section_title text,
  add column if not exists campaigns_section_intro text;

update public.program_guides
set
  guide_kicker = coalesce(guide_kicker, 'PROGRAMGUIDE'),
  reading_time_label = coalesce(reading_time_label, '4 min lesing'),
  strategy_section_title = coalesce(strategy_section_title, 'Slik bør du bruke det'),
  decision_section_title = coalesce(decision_section_title, 'Før du går videre'),
  earning_decision_label = coalesce(earning_decision_label, 'Tjen poeng når'),
  redemption_decision_label = coalesce(redemption_decision_label, 'Bruk poeng når'),
  risk_decision_label = coalesce(risk_decision_label, 'Stopp opp hvis'),
  earning_section_title = coalesce(earning_section_title, 'Slik tjener du poeng'),
  earning_section_intro = coalesce(earning_section_intro, 'Start her før du går for en kampanje.'),
  redemption_section_title = coalesce(redemption_section_title, 'Slik bruker du poengene smart'),
  redemption_section_intro = coalesce(redemption_section_intro, 'Bruk poengene der du ser hva du får igjen.'),
  risk_section_title = coalesce(risk_section_title, 'Vanlige feller'),
  risk_section_intro = coalesce(risk_section_intro, 'Ting som kan gjøre en god kampanje mindre god.'),
  campaigns_section_title = coalesce(campaigns_section_title, 'Kampanjer nå'),
  campaigns_section_intro = coalesce(campaigns_section_intro, 'Aktive kampanjer knyttet til programmet.');
