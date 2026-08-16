begin;

update public.campaigns
set
  summary = '50 000 EuroBonus-poeng i velkomstbonus for SAS Amex Elite i Norge.',
  details = 'SAS oppgir at Amex Elite i Norge gir 50 000 EuroBonus-poeng i velkomstbonus. Kortet gir også 20 poeng per 100 kr og 2 for 1-reiser med SAS og SkyTeam.',
  editorial_summary = 'Stor bonus, men bare verdt det hvis du faktisk vil bruke kortet og 2 for 1-fordelen.',
  updated_at = now()
where id = '4a99a49d-3a3d-40ab-af4d-eade4d0f0401';

update public.campaign_editorial_assessments
set
  reason_why_it_matters = 'Mange poeng i et program norske bonusjegere ofte bruker.',
  estimated_value_text = '50 000 EuroBonus-poeng, pluss 2 for 1-fordel hvis du får brukt den.',
  risk_note = 'Månedsavgiften er høy. Dette passer best hvis du faktisk får brukt reisefordelene.'
where campaign_id = '4a99a49d-3a3d-40ab-af4d-eade4d0f0401';

commit;
