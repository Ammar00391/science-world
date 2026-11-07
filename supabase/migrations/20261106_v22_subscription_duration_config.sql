-- V22: make activation-code periods owner-configurable, not fixed to guessed values.
-- Run only after the V21/V22 bootstrap schema has created public.activation_codes.
begin;

do $$
begin
  if to_regclass('public.activation_codes') is null then
    raise exception 'public.activation_codes is missing; apply the Science World bootstrap schema first';
  end if;
end;
$$;

alter table public.activation_codes
  add column if not exists duration_days integer;

alter table public.activation_codes
  drop constraint if exists activation_codes_duration_days_check;

alter table public.activation_codes
  add constraint activation_codes_duration_days_check
  check (duration_days between 1 and 3650);

alter table public.activation_codes
  alter column duration_days drop default;

comment on column public.activation_codes.duration_days is
  'Subscription period in days. No default is assigned; an authorized admin must explicitly set 1..3650 days. Legacy null rows cannot activate until configured.';

commit;
