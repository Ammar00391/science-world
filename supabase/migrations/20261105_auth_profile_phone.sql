-- Science World V22: preserve the phone number collected during sign-up.
-- Safe to run on an existing V21 database.
begin;

alter table public.profiles
  add column if not exists phone text;

-- Backfill existing accounts when phone was saved in Supabase Auth metadata.
update public.profiles p
set phone = nullif(btrim(u.raw_user_meta_data ->> 'phone'), '')
from auth.users u
where u.id = p.id
  and (p.phone is null or btrim(p.phone) = '')
  and nullif(btrim(u.raw_user_meta_data ->> 'phone'), '') is not null;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_display_name text;
begin
  v_display_name := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'طالب عالم العلوم'
  );

  insert into public.profiles (id, display_name, phone)
  values (
    new.id,
    v_display_name,
    nullif(btrim(new.raw_user_meta_data ->> 'phone'), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

commit;
