do $$
begin
  update public.store_earning_rates rate
  set
    requirement_summary = updates.requirement_summary,
    updated_at = now()
  from (
    values
      (
        'Tibber',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder som ikke er eller har vært kunde hos Tibber, én gang per EuroBonus-medlem og kun for norske EuroBonus-medlemmer. Du må ha vært kunde i minst 3 måneder før poeng utbetales.'
      ),
      (
        'Inkmann',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder, én gang per kunde og ved minimum ordreverdi 250 NOK.'
      ),
      (
        'Trøndermobil',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder og én gang per EuroBonus-medlem. Du må være kunde i minst 3 måneder; SAS oppgir at 1-5 GB ikke gir poeng, kun 10-20 GB + gratis data.'
      ),
      (
        'NordVPN',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder som ikke er eller har vært NordVPN-kunder.'
      ),
      (
        'ICE',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder som ikke har vært aktive de siste 12 månedene og kun én gang per kunde. Du må være kunde i minst 3 måneder; ICE Junior gir ikke poeng.'
      ),
      (
        'Disney+',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun én gang per EuroBonus-medlem, kun nye norske medlemmer og kun ved årlig abonnement.'
      ),
      (
        'Fortum Strøm',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder som ikke er eller har vært kunde hos Fortum, én gang per EuroBonus-medlem og kun for norske EuroBonus-medlemmer. Du må ha vært kunde i minst 3 måneder før poeng utbetales.'
      ),
      (
        'Albert',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. SAS oppgir at tilbudet kun kan brukes én gang per kunde. Hvis du kansellerer abonnementet innen 5 dager, blir bestillingen kansellert.'
      ),
      (
        'Strim',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun én gang per kunde og kun for nye norske kunder som ikke har vært medlem de siste 12 månedene.'
      ),
      (
        'Maxulin',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder som ikke er eller har vært kunder hos Maxulin.'
      ),
      (
        'Storytel',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder og én gang per EuroBonus-medlem.'
      ),
      (
        'HelloFresh',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder med norsk adresse og én gang per medlem. Du tjener kun poeng ved bestilling av minimum 3 ukers måltider.'
      ),
      (
        'BookBeat',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun én gang per kunde og kun for nye norske kunder.'
      ),
      (
        'PlussMobil',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder og én gang per EuroBonus-medlem. Du må være kunde i minst 3 måneder for å tjene poeng.'
      ),
      (
        'Kinoklubb',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun én gang per EuroBonus-medlem og kun for norske medlemmer.'
      ),
      (
        'Memira',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder hos Memira og én gang per medlem. Du tjener poeng når du bestiller gratis test på nett og fullfører den i en av Memiras fysiske butikker.'
      ),
      (
        'SkyShowtime',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder, én gang per medlem og ved bestilling av 1-års abonnement.'
      ),
      (
        'Nextory',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun én gang per kunde og kun for nye norske kunder.'
      ),
      (
        'Telia',
        'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores. Gjelder kun nye kunder som ikke har vært aktive de siste 12 månedene og én gang per EuroBonus-medlem. Du må være kunde i minst 3 måneder; Junior 1 GB, Junior 5 GB og kontantkort gir ikke poeng.'
      )
  ) as updates(store_name, requirement_summary)
  join public.stores store on store.name = updates.store_name
  join public.earning_methods method on method.slug = 'sas-eurobonus-online-shopping'
  where rate.store_id = store.id
    and rate.earning_method_id = method.id
    and rate.status = 'published'
    and store.status = 'published';
end $$;
