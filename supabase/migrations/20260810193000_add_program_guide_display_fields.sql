alter table public.program_guides
  add column if not exists intro_text text,
  add column if not exists value_estimate_label text,
  add column if not exists value_estimate_detail text,
  add column if not exists expiration_summary text,
  add column if not exists expiration_detail text;

update public.program_guides guide
set
  intro_text = 'EuroBonus er nyttig når du har en konkret plan for opptjening og bruk. Guiden hjelper deg å vurdere kampanjer opp mot fleksibilitet, gebyrer og faktisk reisebehov.',
  value_estimate_label = 'Varierer',
  value_estimate_detail = 'Verdien avhenger av reisemål, tilgjengelighet, avgifter og alternativ kontantpris.',
  expiration_summary = 'Sjekk vilkår',
  expiration_detail = 'Kontroller alltid gjeldende utløpsregler hos SAS før du lar saldo ligge lenge.'
from public.bonus_programs program
where program.id = guide.program_id
  and program.slug = 'sas-eurobonus';

update public.program_guides guide
set
  intro_text = 'Trumf er kontantnært og lett å forstå, men totalprisen bør fortsatt styre valget. Bonus er best når den kommer på kjøp du allerede ville gjort.',
  value_estimate_label = '1 kr = 1 kr',
  value_estimate_detail = 'Trumf-bonus er konkret kroneverdi, men kampanjeverdi må vurderes mot totalpris.',
  expiration_summary = 'Lav friksjon',
  expiration_detail = 'Sjekk saldo og overføringsvilkår før du flytter bonus til andre programmer.'
from public.bonus_programs program
where program.id = guide.program_id
  and program.slug = 'trumf';

update public.program_guides guide
set
  intro_text = 'Spenn bør vurderes ut fra partnerne du faktisk bruker. Kampanjer med planlagt kjøp og lav friksjon er normalt mest relevante.',
  value_estimate_label = 'Partnerverdi',
  value_estimate_detail = 'Verdien styres av hvor du kan opptjene og bruke poengene.',
  expiration_summary = 'Følg saldo',
  expiration_detail = 'Kontroller program- og partnervilkår før større opptjening eller bruk.'
from public.bonus_programs program
where program.id = guide.program_id
  and program.slug = 'spenn';
