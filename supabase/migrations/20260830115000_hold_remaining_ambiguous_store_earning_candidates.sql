update public.ingestion_candidates candidate
set
  status = 'needs_review',
  reviewed_at = now(),
  review_note = case candidate.title
    when 'SAS EuroBonus Shopping: Bærum Energi'
      then 'Holdt tilbake fra batchpublisering 2026-08-30: energileverandør/kategori mangler trygg MVP-kategori.'
    when 'SAS EuroBonus Shopping: ELSKLING'
      then 'Holdt tilbake fra batchpublisering 2026-08-30: energisammenligning/kategori mangler trygg MVP-kategori.'
    when 'SAS EuroBonus Shopping: Truestory'
      then 'Holdt tilbake fra batchpublisering 2026-08-30: opplevelses-/gaveaktør; vurder kategori før publisering.'
    when 'SAS EuroBonus Shopping: YouWish'
      then 'Holdt tilbake fra batchpublisering 2026-08-30: opplevelses-/gaveaktør; vurder kategori og mulig overlap mot Trumf-kandidat før publisering.'
    when 'Trumf: YouWish'
      then 'Holdt tilbake fra batchpublisering 2026-08-30: opplevelses-/gaveaktør; vurder kategori og mulig overlap mot SAS-kandidat før publisering.'
    when 'Trumf: YourSurprise'
      then 'Holdt tilbake fra batchpublisering 2026-08-30: personlig gavebutikk; vurder om MVP trenger egen gave/opplevelse-kategori.'
    else 'Holdt tilbake fra batchpublisering 2026-08-30: butikk/kategori er ikke trygg nok til automatisk publisering.'
  end,
  updated_at = now()
where candidate.status = 'new'
  and candidate.title in (
    'SAS EuroBonus Shopping: Bærum Energi',
    'SAS EuroBonus Shopping: Calstop',
    'SAS EuroBonus Shopping: Detailshop',
    'SAS EuroBonus Shopping: ELSKLING',
    'SAS EuroBonus Shopping: Truestory',
    'SAS EuroBonus Shopping: YouWish',
    'Trumf: Backe i Grensen',
    'Trumf: Beredd',
    'Trumf: Comforth Scandinavia',
    'Trumf: Engrospris',
    'Trumf: Karma',
    'Trumf: Stille',
    'Trumf: Tønnesen',
    'Trumf: YourSurprise',
    'Trumf: YouWish'
  );
