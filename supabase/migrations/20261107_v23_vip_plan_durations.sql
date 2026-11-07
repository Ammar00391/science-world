-- V23: lock the approved subscription durations to Silver=30 and Gold=75 days.
-- Existing unconfigured activation codes are assigned the approved tier duration.
begin;

do $$
begin
  if to_regclass('public.activation_codes') is null then
    raise exception 'public.activation_codes is missing; apply the Science World bootstrap schema first';
  end if;
end;
$$;

update public.activation_codes
set duration_days = case lower(tier)
  when 'silver' then 30
  when 'gold' then 75
  else duration_days
end
where is_used = false and lower(tier) in ('silver', 'gold');

alter table public.activation_codes
  drop constraint if exists activation_codes_vip_duration_check;
alter table public.activation_codes
  add constraint activation_codes_vip_duration_check
  check (
    is_used = true
    or (lower(tier) = 'silver' and duration_days = 30)
    or (lower(tier) = 'gold' and duration_days = 75)
  );

comment on column public.activation_codes.duration_days is
  'Approved V23 duration: silver=30 days, gold=75 days. Unused codes are normalized to the approved duration; already-used codes preserve their historical duration.';

commit;
