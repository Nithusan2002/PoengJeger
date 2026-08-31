begin;

delete from public.earning_combination_rates combo_rate
using public.earning_combinations combo,
      public.store_earning_rates rate,
      public.earning_methods method,
      public.stores store
where combo_rate.combination_id = combo.id
  and combo_rate.store_earning_rate_id = rate.id
  and method.id = rate.earning_method_id
  and store.id = combo.store_id
  and store.slug = 'youwish'
  and (
    (combo.title = 'EuroBonus Online Shopping' and method.slug <> 'sas-eurobonus-online-shopping')
    or (combo.title = 'Trumf Netthandel' and method.slug <> 'trumf')
  );

commit;
