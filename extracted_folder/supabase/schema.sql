-- ============================================================================
-- Science World | Supabase bootstrap schema (V20)
-- Target: a NEW Supabase project created for Science World.
-- Run this file ONCE (or re-run safely) in Supabase SQL Editor.
-- This file replaces the old sequence of separate SQL scripts.
-- It does not seed demo content, private activation codes, or administrator users.
-- ============================================================================

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Shared timestamp trigger
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function public.set_updated_at() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Student profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  grade text,
  branch text,
  student_number text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists grade text;
alter table public.profiles add column if not exists branch text;
alter table public.profiles add column if not exists student_number text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

create unique index if not exists profiles_student_number_uidx
  on public.profiles(student_number) where student_number is not null;

create or replace function public.assign_student_number()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.student_number is null or btrim(new.student_number) = '' then
    new.student_number := 'SW-' || upper(substr(replace(new.id::text, '-', ''), 1, 10));
  end if;
  return new;
end;
$$;

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

  insert into public.profiles (id, display_name)
  values (new.id, v_display_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.assign_student_number() from public, anon, authenticated;

drop trigger if exists profiles_01_assign_student_number on public.profiles;
create trigger profiles_01_assign_student_number
before insert on public.profiles
for each row execute function public.assign_student_number();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Books metadata. Actual PDF files/storage policies are configured separately.
-- ---------------------------------------------------------------------------
create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  grade text not null,
  subject text not null,
  chapter text,
  year text,
  edition text,
  publisher text,
  file_url text,
  file_size bigint not null default 0 check (file_size >= 0),
  file_type text default 'application/pdf',
  is_available boolean not null default false,
  is_premium boolean not null default false,
  rights text,
  description text,
  cover_url text,
  page_count integer check (page_count is null or page_count > 0),
  language text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.books add column if not exists edition text;
alter table public.books add column if not exists publisher text;
alter table public.books add column if not exists file_url text;
alter table public.books add column if not exists file_size bigint not null default 0;
alter table public.books add column if not exists file_type text default 'application/pdf';
alter table public.books add column if not exists is_available boolean not null default false;
alter table public.books add column if not exists is_premium boolean not null default false;
alter table public.books add column if not exists rights text;
alter table public.books add column if not exists description text;
alter table public.books add column if not exists cover_url text;
alter table public.books add column if not exists page_count integer;
alter table public.books add column if not exists language text;
alter table public.books add column if not exists created_at timestamptz not null default now();
alter table public.books add column if not exists updated_at timestamptz not null default now();

create index if not exists books_grade_subject_idx on public.books(grade, subject);
create index if not exists books_available_idx on public.books(is_available, is_premium);

drop trigger if exists books_set_updated_at on public.books;
create trigger books_set_updated_at
before update on public.books
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Question bank
-- ---------------------------------------------------------------------------
create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  grade text not null,
  subject text not null,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text not null default 'mcq',
  source text not null default 'manual',
  review_status text not null default 'draft',
  is_paid boolean not null default false,
  question_text text not null default '',
  options jsonb not null default '[]'::jsonb,
  correct_answer text not null default '',
  solution text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint questions_options_array_chk check (jsonb_typeof(options) = 'array')
);

alter table public.questions add column if not exists question_text text not null default '';
alter table public.questions add column if not exists options jsonb not null default '[]'::jsonb;
alter table public.questions add column if not exists school_year text;
alter table public.questions add column if not exists is_paid boolean not null default false;
alter table public.questions add column if not exists correct_answer text not null default '';
alter table public.questions add column if not exists solution text;
alter table public.questions add column if not exists created_at timestamptz not null default now();
alter table public.questions add column if not exists updated_at timestamptz not null default now();

create index if not exists questions_grade_subject_idx on public.questions(grade, subject);
create index if not exists questions_status_paid_idx on public.questions(review_status, is_paid);
create index if not exists questions_created_at_idx on public.questions(created_at desc);

drop trigger if exists questions_set_updated_at on public.questions;
create trigger questions_set_updated_at
before update on public.questions
for each row execute function public.set_updated_at();

create table if not exists public.question_versions (
  question_id uuid not null references public.questions(id) on delete cascade,
  version integer not null check (version > 0),
  content jsonb not null,
  created_at timestamptz not null default now(),
  primary key (question_id, version)
);

create table if not exists public.question_tags (
  question_id uuid not null references public.questions(id) on delete cascade,
  tag text not null,
  primary key (question_id, tag)
);

-- ---------------------------------------------------------------------------
-- Activation codes are created only by a trusted administrator/server.
-- Create this table BEFORE subscriptions because subscriptions references it.
-- ---------------------------------------------------------------------------
create table if not exists public.activation_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  tier text not null default 'silver' check (tier in ('silver', 'gold')),
  duration_days integer not null check (duration_days between 1 and 3650),
  is_used boolean not null default false,
  used_by uuid references auth.users(id) on delete set null,
  used_at timestamptz,
  expires_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  batch_id uuid,
  created_at timestamptz not null default now()
);

alter table public.activation_codes add column if not exists tier text not null default 'silver';
alter table public.activation_codes add column if not exists duration_days integer;
alter table public.activation_codes alter column duration_days drop default;

-- Periods are configurable by the owner; do not hard-code an unapproved plan duration.
alter table public.activation_codes drop constraint if exists activation_codes_duration_days_check;
alter table public.activation_codes add constraint activation_codes_duration_days_check
  check (duration_days between 1 and 3650);
alter table public.activation_codes add column if not exists is_used boolean not null default false;
alter table public.activation_codes add column if not exists used_by uuid references auth.users(id) on delete set null;
alter table public.activation_codes add column if not exists used_at timestamptz;
alter table public.activation_codes add column if not exists expires_at timestamptz;
alter table public.activation_codes add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.activation_codes add column if not exists batch_id uuid;
alter table public.activation_codes add column if not exists created_at timestamptz not null default now();

-- One subscription row per user is required by the app's maybeSingle() query.
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'free' check (status in ('free', 'premium', 'expired')),
  tier text not null default 'silver' check (tier in ('silver', 'gold')),
  starts_at timestamptz,
  expires_at timestamptz,
  activated_by_code_id uuid references public.activation_codes(id) on delete set null,
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subscriptions add column if not exists tier text not null default 'silver';
alter table public.subscriptions add column if not exists starts_at timestamptz;
alter table public.subscriptions add column if not exists expires_at timestamptz;
alter table public.subscriptions add column if not exists activated_by_code_id uuid references public.activation_codes(id) on delete set null;
alter table public.subscriptions add column if not exists source text not null default 'manual';
alter table public.subscriptions add column if not exists created_at timestamptz not null default now();
alter table public.subscriptions add column if not exists updated_at timestamptz not null default now();

create unique index if not exists subscriptions_user_id_uidx on public.subscriptions(user_id);
create index if not exists subscriptions_active_lookup_idx on public.subscriptions(user_id, status, expires_at);

drop trigger if exists subscriptions_set_updated_at on public.subscriptions;
create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

create table if not exists public.activation_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  code_id uuid references public.activation_codes(id) on delete set null,
  success boolean not null,
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists activation_logs_user_time_idx
  on public.activation_logs(user_id, created_at desc);

-- Manual payment requests; approval must be performed by a trusted admin/server.
create table if not exists public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text,
  phone text,
  receipt_url text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_requests_user_time_idx
  on public.payment_requests(user_id, created_at desc);

drop trigger if exists payment_requests_set_updated_at on public.payment_requests;
create trigger payment_requests_set_updated_at
before update on public.payment_requests
for each row execute function public.set_updated_at();

-- Minimal read-only history table used by the current student progress screen.
-- Writes are intentionally not granted until a trusted exam-submission flow exists.
create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exam_id uuid,
  grade text,
  subject text,
  total_questions integer not null default 0 check (total_questions >= 0),
  correct_answers integer not null default 0 check (correct_answers >= 0),
  score numeric(5,2),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists exam_attempts_user_time_idx
  on public.exam_attempts(user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Replace legacy/overlapping policies on only the app tables below.
-- Policies are permissive by default (OR); removing old policies prevents an
-- older broad policy from accidentally bypassing the new subscription check.
-- ---------------------------------------------------------------------------
do $$
declare
  v_table text;
  v_policy record;
begin
  foreach v_table in array array[
    'profiles', 'books', 'questions', 'question_versions', 'question_tags',
    'activation_codes', 'subscriptions', 'activation_logs', 'payment_requests',
    'exam_attempts'
  ] loop
    for v_policy in
      select policyname
      from pg_policies
      where schemaname = 'public' and tablename = v_table
    loop
      execute format('drop policy if exists %I on public.%I', v_policy.policyname, v_table);
    end loop;
  end loop;
end;
$$;

alter table public.profiles enable row level security;
alter table public.books enable row level security;
alter table public.questions enable row level security;
alter table public.question_versions enable row level security;
alter table public.question_tags enable row level security;
alter table public.activation_codes enable row level security;
alter table public.subscriptions enable row level security;
alter table public.activation_logs enable row level security;
alter table public.payment_requests enable row level security;
alter table public.exam_attempts enable row level security;

-- Profiles: a user can see and edit only their own permitted profile fields.
create policy profiles_select_own on public.profiles
  for select to authenticated using (auth.uid() = id);
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (auth.uid() = id);
create policy profiles_update_own on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Books: authenticated students see available free books, or premium books
-- only while their own subscription is active.
create policy books_select_entitled on public.books
  for select to authenticated
  using (
    is_available = true
    and (
      is_premium = false
      or exists (
        select 1 from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.expires_at is null or s.expires_at > now())
      )
    )
  );

-- Questions are not directly selectable by client roles. Student access is
-- provided only by the column-limited get_questions RPC below.

-- question_versions.content may contain answer keys and solutions, so these
-- internal question metadata tables are not directly readable by students.

-- Subscription state is readable by its owner only; clients cannot change it.
create policy subscriptions_select_own on public.subscriptions
  for select to authenticated using (auth.uid() = user_id);

create policy activation_logs_select_own on public.activation_logs
  for select to authenticated using (auth.uid() = user_id);

create policy payment_requests_select_own on public.payment_requests
  for select to authenticated using (auth.uid() = user_id);
create policy payment_requests_insert_own on public.payment_requests
  for insert to authenticated with check (auth.uid() = user_id);

create policy exam_attempts_select_own on public.exam_attempts
  for select to authenticated using (auth.uid() = user_id);

-- Explicit grants. RLS policies alone are not a substitute for SQL privileges.
revoke all on table public.profiles, public.books, public.questions,
  public.question_versions, public.question_tags, public.activation_codes,
  public.subscriptions, public.activation_logs, public.payment_requests,
  public.exam_attempts from anon, authenticated;

-- Profile writes are limited to editable fields; student_number is server-generated.
grant select on public.profiles to authenticated;
grant insert (id, display_name, grade, branch, avatar_url) on public.profiles to authenticated;
grant update (id, display_name, grade, branch, avatar_url, updated_at) on public.profiles to authenticated;

grant select on public.books to authenticated;
grant select on public.subscriptions, public.activation_logs to authenticated;
grant select on public.payment_requests to authenticated;
grant insert (user_id, name, phone, receipt_url) on public.payment_requests to authenticated;
grant select on public.exam_attempts to authenticated;
-- No direct client grants are given on activation_codes.

-- ---------------------------------------------------------------------------
-- Secure question retrieval and answer-check RPCs.
-- Client roles must never SELECT the questions table directly because it
-- contains correct_answer and solution. The retrieval function returns only
-- safe question fields; answer evaluation stays on the database server.
-- ---------------------------------------------------------------------------
drop function if exists public.get_questions(text, text, text, text);
create function public.get_questions(
  p_grade text default null,
  p_subject text default null,
  p_type text default null,
  p_difficulty text default null
)
returns table (
  id uuid,
  grade text,
  subject text,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text,
  source text,
  review_status text,
  is_paid boolean,
  question_text text,
  options jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    q.id,
    q.grade,
    q.subject,
    q.chapter,
    q.lesson,
    q.school_year,
    q.difficulty,
    q.type,
    q.source,
    q.review_status,
    q.is_paid,
    q.question_text,
    q.options,
    q.created_at,
    q.updated_at
  from public.questions q
  where auth.uid() is not null
    and q.review_status in ('published', 'approved')
    and (p_grade is null or q.grade = p_grade)
    and (p_subject is null or q.subject = p_subject)
    and (p_type is null or q.type = p_type)
    and (p_difficulty is null or q.difficulty = p_difficulty)
    and (
      q.is_paid = false
      or exists (
        select 1
        from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.expires_at is null or s.expires_at > now())
      )
    );
$function$;
revoke all on function public.get_questions(text, text, text, text) from public, anon;
grant execute on function public.get_questions(text, text, text, text) to authenticated;

-- Fetch one question by ID without transferring answer-key columns.
create or replace function public.get_question_by_id(p_question_id uuid)
returns table (
  id uuid,
  grade text,
  subject text,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text,
  source text,
  review_status text,
  is_paid boolean,
  question_text text,
  options jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    q.id, q.grade, q.subject, q.chapter, q.lesson, q.school_year,
    q.difficulty, q.type, q.source, q.review_status, q.is_paid,
    q.question_text, q.options, q.created_at, q.updated_at
  from public.questions q
  where auth.uid() is not null
    and q.id = p_question_id
    and q.review_status in ('published', 'approved')
    and (
      q.is_paid = false
      or exists (
        select 1 from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.expires_at is null or s.expires_at > now())
      )
    );
$function$;
revoke all on function public.get_question_by_id(uuid) from public, anon;
grant execute on function public.get_question_by_id(uuid) to authenticated;

-- A student's selected answer is checked on the server. The function returns
-- only a boolean and reveals the solution only after a correct response.
create or replace function public.check_question_answer(
  p_question_id uuid,
  p_answer text
)
returns table (
  is_correct boolean,
  solution text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_correct_answer text;
  v_solution text;
  v_is_paid boolean;
  v_is_correct boolean;
begin
  if v_uid is null then
    return query select false, null::text;
    return;
  end if;

  select q.correct_answer, q.solution, q.is_paid
    into v_correct_answer, v_solution, v_is_paid
  from public.questions q
  where q.id = p_question_id
    and q.review_status in ('published', 'approved');

  if not found then
    return query select false, null::text;
    return;
  end if;

  if v_is_paid and not exists (
    select 1
    from public.subscriptions s
    where s.user_id = v_uid
      and s.status = 'premium'
      and (s.expires_at is null or s.expires_at > now())
  ) then
    return query select false, null::text;
    return;
  end if;

  v_is_correct := lower(btrim(coalesce(p_answer, ''))) =
                  lower(btrim(coalesce(v_correct_answer, '')));

  return query
    select v_is_correct,
           case when v_is_correct then v_solution else null::text end;
end;
$function$;
revoke all on function public.check_question_answer(uuid, text) from public, anon;
grant execute on function public.check_question_answer(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Secure one-time activation RPC. Client-supplied user_id must equal auth.uid.
-- Activation-code hashes are generated with:
--   crypt(upper('YOUR-NEW-CODE'), gen_salt('bf'))
-- Do NOT place real codes or owner emails in source control.
-- ---------------------------------------------------------------------------
drop function if exists public.activate_subscription(uuid, text);
create function public.activate_subscription(p_user_id uuid, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions, auth
as $$
declare
  v_uid uuid := auth.uid();
  v_code_id uuid;
  v_tier text;
  v_duration_days integer;
  v_attempts integer;
  v_now timestamptz := now();
begin
  if v_uid is null or p_user_id is distinct from v_uid
     or p_code is null or length(btrim(p_code)) < 6 then
    return false;
  end if;

  select count(*) into v_attempts
  from public.activation_logs l
  where l.user_id = v_uid
    and l.success = false
    and l.created_at > v_now - interval '1 hour';

  if v_attempts >= 5 then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, null, false, 'too_many_attempts');
    return false;
  end if;

  -- Correct bcrypt verification: crypt(candidate, stored_hash) = stored_hash.
  -- Lock the matching code row so two simultaneous requests cannot redeem it.
  select c.id, c.tier, c.duration_days
    into v_code_id, v_tier, v_duration_days
  from public.activation_codes c
  where c.is_used = false
    and (c.expires_at is null or c.expires_at > v_now)
    and c.code_hash = crypt(upper(btrim(p_code)), c.code_hash)
  for update;

  if v_code_id is null then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, null, false, 'invalid_or_unavailable_code');
    return false;
  end if;

  if v_tier not in ('silver', 'gold') or v_duration_days is null
     or v_duration_days < 1 or v_duration_days > 3650 then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, v_code_id, false, 'invalid_plan_configuration');
    return false;
  end if;

  update public.activation_codes
  set is_used = true, used_by = v_uid, used_at = v_now
  where id = v_code_id and is_used = false;

  if not found then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, v_code_id, false, 'code_already_used');
    return false;
  end if;

  insert into public.subscriptions as existing_subscription (
    user_id, status, tier, starts_at, expires_at,
    activated_by_code_id, source
  ) values (
    v_uid, 'premium', v_tier, v_now,
    v_now + make_interval(days => v_duration_days),
    v_code_id, 'code'
  )
  on conflict (user_id) do update set
    status = 'premium',
    tier = excluded.tier,
    starts_at = case
      when existing_subscription.status = 'premium'
       and existing_subscription.expires_at > v_now
      then existing_subscription.starts_at
      else v_now
    end,
    expires_at = case
      when existing_subscription.status = 'premium'
       and existing_subscription.expires_at is null
      then null
      when existing_subscription.status = 'premium'
       and existing_subscription.expires_at > v_now
      then existing_subscription.expires_at + make_interval(days => v_duration_days)
      else v_now + make_interval(days => v_duration_days)
    end,
    activated_by_code_id = excluded.activated_by_code_id,
    source = 'code',
    updated_at = v_now;

  insert into public.activation_logs(user_id, code_id, success, reason)
  values (v_uid, v_code_id, true, 'activated');

  return true;
end;
$$;

revoke all on function public.activate_subscription(uuid, text) from public, anon;
grant execute on function public.activate_subscription(uuid, text) to authenticated;

commit;

-- Expected after success:
-- profiles, books, questions, question_versions, question_tags,
-- activation_codes, subscriptions, activation_logs, payment_requests,
-- exam_attempts.
-- Do not run legacy SQL files separately after this bootstrap.

-- ============================================================================
-- Science World | Supabase bootstrap schema (V20)
-- Target: a NEW Supabase project created for Science World.
-- Run this file ONCE (or re-run safely) in Supabase SQL Editor.
-- This file replaces the old sequence of separate SQL scripts.
-- It does not seed demo content, private activation codes, or administrator users.
-- ============================================================================

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Shared timestamp trigger
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function public.set_updated_at() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Student profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  grade text,
  branch text,
  student_number text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists grade text;
alter table public.profiles add column if not exists branch text;
alter table public.profiles add column if not exists student_number text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

create unique index if not exists profiles_student_number_uidx
  on public.profiles(student_number) where student_number is not null;

create or replace function public.assign_student_number()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.student_number is null or btrim(new.student_number) = '' then
    new.student_number := 'SW-' || upper(substr(replace(new.id::text, '-', ''), 1, 10));
  end if;
  return new;
end;
$$;

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

  insert into public.profiles (id, display_name)
  values (new.id, v_display_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.assign_student_number() from public, anon, authenticated;

drop trigger if exists profiles_01_assign_student_number on public.profiles;
create trigger profiles_01_assign_student_number
before insert on public.profiles
for each row execute function public.assign_student_number();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Books metadata. Actual PDF files/storage policies are configured separately.
-- ---------------------------------------------------------------------------
create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  grade text not null,
  subject text not null,
  chapter text,
  year text,
  edition text,
  publisher text,
  file_url text,
  file_size bigint not null default 0 check (file_size >= 0),
  file_type text default 'application/pdf',
  is_available boolean not null default false,
  is_premium boolean not null default false,
  rights text,
  description text,
  cover_url text,
  page_count integer check (page_count is null or page_count > 0),
  language text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.books add column if not exists edition text;
alter table public.books add column if not exists publisher text;
alter table public.books add column if not exists file_url text;
alter table public.books add column if not exists file_size bigint not null default 0;
alter table public.books add column if not exists file_type text default 'application/pdf';
alter table public.books add column if not exists is_available boolean not null default false;
alter table public.books add column if not exists is_premium boolean not null default false;
alter table public.books add column if not exists rights text;
alter table public.books add column if not exists description text;
alter table public.books add column if not exists cover_url text;
alter table public.books add column if not exists page_count integer;
alter table public.books add column if not exists language text;
alter table public.books add column if not exists created_at timestamptz not null default now();
alter table public.books add column if not exists updated_at timestamptz not null default now();

create index if not exists books_grade_subject_idx on public.books(grade, subject);
create index if not exists books_available_idx on public.books(is_available, is_premium);

drop trigger if exists books_set_updated_at on public.books;
create trigger books_set_updated_at
before update on public.books
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Question bank
-- ---------------------------------------------------------------------------
create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  grade text not null,
  subject text not null,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text not null default 'mcq',
  source text not null default 'manual',
  review_status text not null default 'draft',
  is_paid boolean not null default false,
  question_text text not null default '',
  options jsonb not null default '[]'::jsonb,
  correct_answer text not null default '',
  solution text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint questions_options_array_chk check (jsonb_typeof(options) = 'array')
);

alter table public.questions add column if not exists question_text text not null default '';
alter table public.questions add column if not exists options jsonb not null default '[]'::jsonb;
alter table public.questions add column if not exists school_year text;
alter table public.questions add column if not exists is_paid boolean not null default false;
alter table public.questions add column if not exists correct_answer text not null default '';
alter table public.questions add column if not exists solution text;
alter table public.questions add column if not exists created_at timestamptz not null default now();
alter table public.questions add column if not exists updated_at timestamptz not null default now();

create index if not exists questions_grade_subject_idx on public.questions(grade, subject);
create index if not exists questions_status_paid_idx on public.questions(review_status, is_paid);
create index if not exists questions_created_at_idx on public.questions(created_at desc);

drop trigger if exists questions_set_updated_at on public.questions;
create trigger questions_set_updated_at
before update on public.questions
for each row execute function public.set_updated_at();

create table if not exists public.question_versions (
  question_id uuid not null references public.questions(id) on delete cascade,
  version integer not null check (version > 0),
  content jsonb not null,
  created_at timestamptz not null default now(),
  primary key (question_id, version)
);

create table if not exists public.question_tags (
  question_id uuid not null references public.questions(id) on delete cascade,
  tag text not null,
  primary key (question_id, tag)
);

-- ---------------------------------------------------------------------------
-- Activation codes are created only by a trusted administrator/server.
-- Create this table BEFORE subscriptions because subscriptions references it.
-- ---------------------------------------------------------------------------
create table if not exists public.activation_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  tier text not null default 'silver' check (tier in ('silver', 'gold')),
  duration_days integer not null check (duration_days between 1 and 3650),
  is_used boolean not null default false,
  used_by uuid references auth.users(id) on delete set null,
  used_at timestamptz,
  expires_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  batch_id uuid,
  created_at timestamptz not null default now()
);

alter table public.activation_codes add column if not exists tier text not null default 'silver';
alter table public.activation_codes add column if not exists duration_days integer;
alter table public.activation_codes alter column duration_days drop default;

-- Periods are configurable by the owner; do not hard-code an unapproved plan duration.
alter table public.activation_codes drop constraint if exists activation_codes_duration_days_check;
alter table public.activation_codes add constraint activation_codes_duration_days_check
  check (duration_days between 1 and 3650);
alter table public.activation_codes add column if not exists is_used boolean not null default false;
alter table public.activation_codes add column if not exists used_by uuid references auth.users(id) on delete set null;
alter table public.activation_codes add column if not exists used_at timestamptz;
alter table public.activation_codes add column if not exists expires_at timestamptz;
alter table public.activation_codes add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.activation_codes add column if not exists batch_id uuid;
alter table public.activation_codes add column if not exists created_at timestamptz not null default now();

-- One subscription row per user is required by the app's maybeSingle() query.
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'free' check (status in ('free', 'premium', 'expired')),
  tier text not null default 'silver' check (tier in ('silver', 'gold')),
  starts_at timestamptz,
  expires_at timestamptz,
  activated_by_code_id uuid references public.activation_codes(id) on delete set null,
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subscriptions add column if not exists tier text not null default 'silver';
alter table public.subscriptions add column if not exists starts_at timestamptz;
alter table public.subscriptions add column if not exists expires_at timestamptz;
alter table public.subscriptions add column if not exists activated_by_code_id uuid references public.activation_codes(id) on delete set null;
alter table public.subscriptions add column if not exists source text not null default 'manual';
alter table public.subscriptions add column if not exists created_at timestamptz not null default now();
alter table public.subscriptions add column if not exists updated_at timestamptz not null default now();

create unique index if not exists subscriptions_user_id_uidx on public.subscriptions(user_id);
create index if not exists subscriptions_active_lookup_idx on public.subscriptions(user_id, status, expires_at);

drop trigger if exists subscriptions_set_updated_at on public.subscriptions;
create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

create table if not exists public.activation_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  code_id uuid references public.activation_codes(id) on delete set null,
  success boolean not null,
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists activation_logs_user_time_idx
  on public.activation_logs(user_id, created_at desc);

-- Manual payment requests; approval must be performed by a trusted admin/server.
create table if not exists public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text,
  phone text,
  receipt_url text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_requests_user_time_idx
  on public.payment_requests(user_id, created_at desc);

drop trigger if exists payment_requests_set_updated_at on public.payment_requests;
create trigger payment_requests_set_updated_at
before update on public.payment_requests
for each row execute function public.set_updated_at();

-- Minimal read-only history table used by the current student progress screen.
-- Writes are intentionally not granted until a trusted exam-submission flow exists.
create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exam_id uuid,
  grade text,
  subject text,
  total_questions integer not null default 0 check (total_questions >= 0),
  correct_answers integer not null default 0 check (correct_answers >= 0),
  score numeric(5,2),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists exam_attempts_user_time_idx
  on public.exam_attempts(user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Replace legacy/overlapping policies on only the app tables below.
-- Policies are permissive by default (OR); removing old policies prevents an
-- older broad policy from accidentally bypassing the new subscription check.
-- ---------------------------------------------------------------------------
do $$
declare
  v_table text;
  v_policy record;
begin
  foreach v_table in array array[
    'profiles', 'books', 'questions', 'question_versions', 'question_tags',
    'activation_codes', 'subscriptions', 'activation_logs', 'payment_requests',
    'exam_attempts'
  ] loop
    for v_policy in
      select policyname
      from pg_policies
      where schemaname = 'public' and tablename = v_table
    loop
      execute format('drop policy if exists %I on public.%I', v_policy.policyname, v_table);
    end loop;
  end loop;
end;
$$;

alter table public.profiles enable row level security;
alter table public.books enable row level security;
alter table public.questions enable row level security;
alter table public.question_versions enable row level security;
alter table public.question_tags enable row level security;
alter table public.activation_codes enable row level security;
alter table public.subscriptions enable row level security;
alter table public.activation_logs enable row level security;
alter table public.payment_requests enable row level security;
alter table public.exam_attempts enable row level security;

-- Profiles: a user can see and edit only their own permitted profile fields.
create policy profiles_select_own on public.profiles
  for select to authenticated using (auth.uid() = id);
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (auth.uid() = id);
create policy profiles_update_own on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Books: authenticated students see available free books, or premium books
-- only while their own subscription is active.
create policy books_select_entitled on public.books
  for select to authenticated
  using (
    is_available = true
    and (
      is_premium = false
      or exists (
        select 1 from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.expires_at is null or s.expires_at > now())
      )
    )
  );

-- Questions are not directly selectable by client roles. Student access is
-- provided only by the column-limited get_questions RPC below.

-- question_versions.content may contain answer keys and solutions, so these
-- internal question metadata tables are not directly readable by students.

-- Subscription state is readable by its owner only; clients cannot change it.
create policy subscriptions_select_own on public.subscriptions
  for select to authenticated using (auth.uid() = user_id);

create policy activation_logs_select_own on public.activation_logs
  for select to authenticated using (auth.uid() = user_id);

create policy payment_requests_select_own on public.payment_requests
  for select to authenticated using (auth.uid() = user_id);
create policy payment_requests_insert_own on public.payment_requests
  for insert to authenticated with check (auth.uid() = user_id);

create policy exam_attempts_select_own on public.exam_attempts
  for select to authenticated using (auth.uid() = user_id);

-- Explicit grants. RLS policies alone are not a substitute for SQL privileges.
revoke all on table public.profiles, public.books, public.questions,
  public.question_versions, public.question_tags, public.activation_codes,
  public.subscriptions, public.activation_logs, public.payment_requests,
  public.exam_attempts from anon, authenticated;

-- Profile writes are limited to editable fields; student_number is server-generated.
grant select on public.profiles to authenticated;
grant insert (id, display_name, grade, branch, avatar_url) on public.profiles to authenticated;
grant update (id, display_name, grade, branch, avatar_url, updated_at) on public.profiles to authenticated;

grant select on public.books to authenticated;
grant select on public.subscriptions, public.activation_logs to authenticated;
grant select on public.payment_requests to authenticated;
grant insert (user_id, name, phone, receipt_url) on public.payment_requests to authenticated;
grant select on public.exam_attempts to authenticated;
-- No direct client grants are given on activation_codes.

-- ---------------------------------------------------------------------------
-- Secure question retrieval and answer-check RPCs.
-- Client roles must never SELECT the questions table directly because it
-- contains correct_answer and solution. The retrieval function returns only
-- safe question fields; answer evaluation stays on the database server.
-- ---------------------------------------------------------------------------
drop function if exists public.get_questions(text, text, text, text);
create function public.get_questions(
  p_grade text default null,
  p_subject text default null,
  p_type text default null,
  p_difficulty text default null
)
returns table (
  id uuid,
  grade text,
  subject text,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text,
  source text,
  review_status text,
  is_paid boolean,
  question_text text,
  options jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    q.id,
    q.grade,
    q.subject,
    q.chapter,
    q.lesson,
    q.school_year,
    q.difficulty,
    q.type,
    q.source,
    q.review_status,
    q.is_paid,
    q.question_text,
    q.options,
    q.created_at,
    q.updated_at
  from public.questions q
  where auth.uid() is not null
    and q.review_status in ('published', 'approved')
    and (p_grade is null or q.grade = p_grade)
    and (p_subject is null or q.subject = p_subject)
    and (p_type is null or q.type = p_type)
    and (p_difficulty is null or q.difficulty = p_difficulty)
    and (
      q.is_paid = false
      or exists (
        select 1
        from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.expires_at is null or s.expires_at > now())
      )
    );
$function$;
revoke all on function public.get_questions(text, text, text, text) from public, anon;
grant execute on function public.get_questions(text, text, text, text) to authenticated;

-- Fetch one question by ID without transferring answer-key columns.
create or replace function public.get_question_by_id(p_question_id uuid)
returns table (
  id uuid,
  grade text,
  subject text,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text,
  source text,
  review_status text,
  is_paid boolean,
  question_text text,
  options jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    q.id, q.grade, q.subject, q.chapter, q.lesson, q.school_year,
    q.difficulty, q.type, q.source, q.review_status, q.is_paid,
    q.question_text, q.options, q.created_at, q.updated_at
  from public.questions q
  where auth.uid() is not null
    and q.id = p_question_id
    and q.review_status in ('published', 'approved')
    and (
      q.is_paid = false
      or exists (
        select 1 from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.expires_at is null or s.expires_at > now())
      )
    );
$function$;
revoke all on function public.get_question_by_id(uuid) from public, anon;
grant execute on function public.get_question_by_id(uuid) to authenticated;

-- A student's selected answer is checked on the server. The function returns
-- only a boolean and reveals the solution only after a correct response.
create or replace function public.check_question_answer(
  p_question_id uuid,
  p_answer text
)
returns table (
  is_correct boolean,
  solution text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_correct_answer text;
  v_solution text;
  v_is_paid boolean;
  v_is_correct boolean;
begin
  if v_uid is null then
    return query select false, null::text;
    return;
  end if;

  select q.correct_answer, q.solution, q.is_paid
    into v_correct_answer, v_solution, v_is_paid
  from public.questions q
  where q.id = p_question_id
    and q.review_status in ('published', 'approved');

  if not found then
    return query select false, null::text;
    return;
  end if;

  if v_is_paid and not exists (
    select 1
    from public.subscriptions s
    where s.user_id = v_uid
      and s.status = 'premium'
      and (s.expires_at is null or s.expires_at > now())
  ) then
    return query select false, null::text;
    return;
  end if;

  v_is_correct := lower(btrim(coalesce(p_answer, ''))) =
                  lower(btrim(coalesce(v_correct_answer, '')));

  return query
    select v_is_correct,
           case when v_is_correct then v_solution else null::text end;
end;
$function$;
revoke all on function public.check_question_answer(uuid, text) from public, anon;
grant execute on function public.check_question_answer(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Secure one-time activation RPC. Client-supplied user_id must equal auth.uid.
-- Activation-code hashes are generated with:
--   crypt(upper('YOUR-NEW-CODE'), gen_salt('bf'))
-- Do NOT place real codes or owner emails in source control.
-- ---------------------------------------------------------------------------
drop function if exists public.activate_subscription(uuid, text);
create function public.activate_subscription(p_user_id uuid, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions, auth
as $$
declare
  v_uid uuid := auth.uid();
  v_code_id uuid;
  v_tier text;
  v_duration_days integer;
  v_attempts integer;
  v_now timestamptz := now();
begin
  if v_uid is null or p_user_id is distinct from v_uid
     or p_code is null or length(btrim(p_code)) < 6 then
    return false;
  end if;

  select count(*) into v_attempts
  from public.activation_logs l
  where l.user_id = v_uid
    and l.success = false
    and l.created_at > v_now - interval '1 hour';

  if v_attempts >= 5 then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, null, false, 'too_many_attempts');
    return false;
  end if;

  -- Correct bcrypt verification: crypt(candidate, stored_hash) = stored_hash.
  -- Lock the matching code row so two simultaneous requests cannot redeem it.
  select c.id, c.tier, c.duration_days
    into v_code_id, v_tier, v_duration_days
  from public.activation_codes c
  where c.is_used = false
    and (c.expires_at is null or c.expires_at > v_now)
    and c.code_hash = crypt(upper(btrim(p_code)), c.code_hash)
  for update;

  if v_code_id is null then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, null, false, 'invalid_or_unavailable_code');
    return false;
  end if;

  if v_tier not in ('silver', 'gold') or v_duration_days is null
     or v_duration_days < 1 or v_duration_days > 3650 then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, v_code_id, false, 'invalid_plan_configuration');
    return false;
  end if;

  update public.activation_codes
  set is_used = true, used_by = v_uid, used_at = v_now
  where id = v_code_id and is_used = false;

  if not found then
    insert into public.activation_logs(user_id, code_id, success, reason)
    values (v_uid, v_code_id, false, 'code_already_used');
    return false;
  end if;

  insert into public.subscriptions as existing_subscription (
    user_id, status, tier, starts_at, expires_at,
    activated_by_code_id, source
  ) values (
    v_uid, 'premium', v_tier, v_now,
    v_now + make_interval(days => v_duration_days),
    v_code_id, 'code'
  )
  on conflict (user_id) do update set
    status = 'premium',
    tier = excluded.tier,
    starts_at = case
      when existing_subscription.status = 'premium'
       and existing_subscription.expires_at > v_now
      then existing_subscription.starts_at
      else v_now
    end,
    expires_at = case
      when existing_subscription.status = 'premium'
       and existing_subscription.expires_at is null
      then null
      when existing_subscription.status = 'premium'
       and existing_subscription.expires_at > v_now
      then existing_subscription.expires_at + make_interval(days => v_duration_days)
      else v_now + make_interval(days => v_duration_days)
    end,
    activated_by_code_id = excluded.activated_by_code_id,
    source = 'code',
    updated_at = v_now;

  insert into public.activation_logs(user_id, code_id, success, reason)
  values (v_uid, v_code_id, true, 'activated');

  return true;
end;
$$;

revoke all on function public.activate_subscription(uuid, text) from public, anon;
grant execute on function public.activate_subscription(uuid, text) to authenticated;

commit;

-- Expected after success:
-- profiles, books, questions, question_versions, question_tags,
-- activation_codes, subscriptions, activation_logs, payment_requests,
-- exam_attempts.
-- Do not run legacy SQL files separately after this bootstrap.

-- Science World A1 / V24
-- Enforce free, Silver, and Gold question quotas at the database boundary.
-- Free: up to 6 free questions per lesson.
-- Silver: the same 6 free questions plus up to 2 paid questions per lesson.
-- Gold: every approved/published question per lesson.
-- No answer key or solution is returned by retrieval RPCs.
begin;

create index if not exists questions_lesson_entitlement_idx
  on public.questions(grade, subject, chapter, lesson, is_paid, review_status, created_at, id);

-- Student clients must never bypass the RPCs and read answer keys directly.
revoke all on table public.questions from public, anon, authenticated;
revoke all on table public.question_versions, public.question_tags from public, anon, authenticated;

-- Internal helper: decide access based on the authenticated user's own active
-- subscription and the question's rank within its exact lesson + paid/free set.
create or replace function public._science_world_can_access_question(p_question_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  with ranked_questions as (
    select
      q.id,
      q.is_paid,
      row_number() over (
        partition by q.grade, q.subject, coalesce(q.chapter, ''),
                     coalesce(q.lesson, ''), q.is_paid
        order by q.created_at asc, q.id asc
      ) as lesson_position
    from public.questions q
    where q.review_status in ('published', 'approved')
  ),
  user_tier as (
    select coalesce(
      (
        select case when lower(s.tier) = 'gold' then 'gold' else 'silver' end
        from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.starts_at is null or s.starts_at <= now())
          and (s.expires_at is null or s.expires_at > now())
        limit 1
      ),
      'free'
    ) as tier
  )
  select coalesce((
    select
      case
        when t.tier = 'gold' then true
        when q.is_paid = false then q.lesson_position <= 6
        when t.tier = 'silver' then q.lesson_position <= 2
        else false
      end
    from ranked_questions q
    cross join user_tier t
    where q.id = p_question_id
  ), false);
$function$;
revoke all on function public._science_world_can_access_question(uuid) from public, anon, authenticated;

create or replace function public.get_questions(
  p_grade text default null,
  p_subject text default null,
  p_type text default null,
  p_difficulty text default null
)
returns table (
  id uuid,
  grade text,
  subject text,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text,
  source text,
  review_status text,
  is_paid boolean,
  question_text text,
  options jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  with user_tier as (
    select coalesce(
      (
        select case when lower(s.tier) = 'gold' then 'gold' else 'silver' end
        from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.starts_at is null or s.starts_at <= now())
          and (s.expires_at is null or s.expires_at > now())
        limit 1
      ),
      'free'
    ) as tier
  ),
  ranked_questions as (
    select
      q.*,
      row_number() over (
        partition by q.grade, q.subject, coalesce(q.chapter, ''),
                     coalesce(q.lesson, ''), q.is_paid
        order by q.created_at asc, q.id asc
      ) as lesson_position
    from public.questions q
    where auth.uid() is not null
      and q.review_status in ('published', 'approved')
  )
  select
    q.id, q.grade, q.subject, q.chapter, q.lesson, q.school_year,
    q.difficulty, q.type, q.source, q.review_status, q.is_paid,
    q.question_text, q.options, q.created_at, q.updated_at
  from ranked_questions q
  cross join user_tier t
  where (p_grade is null or q.grade = p_grade)
    and (p_subject is null or q.subject = p_subject)
    and (p_type is null or q.type = p_type)
    and (p_difficulty is null or q.difficulty = p_difficulty)
    and (
      t.tier = 'gold'
      or (q.is_paid = false and q.lesson_position <= 6)
      or (q.is_paid = true and t.tier = 'silver' and q.lesson_position <= 2)
    )
  order by q.created_at asc, q.id asc;
$function$;
revoke all on function public.get_questions(text, text, text, text) from public, anon;
grant execute on function public.get_questions(text, text, text, text) to authenticated;

create or replace function public.get_question_by_id(p_question_id uuid)
returns table (
  id uuid,
  grade text,
  subject text,
  chapter text,
  lesson text,
  school_year text,
  difficulty text,
  type text,
  source text,
  review_status text,
  is_paid boolean,
  question_text text,
  options jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    q.id, q.grade, q.subject, q.chapter, q.lesson, q.school_year,
    q.difficulty, q.type, q.source, q.review_status, q.is_paid,
    q.question_text, q.options, q.created_at, q.updated_at
  from public.questions q
  where q.id = p_question_id
    and auth.uid() is not null
    and q.review_status in ('published', 'approved')
    and public._science_world_can_access_question(q.id);
$function$;
revoke all on function public.get_question_by_id(uuid) from public, anon;
grant execute on function public.get_question_by_id(uuid) to authenticated;

create or replace function public.check_question_answer(
  p_question_id uuid,
  p_answer text
)
returns table (is_correct boolean, solution text)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_correct_answer text;
  v_solution text;
begin
  if auth.uid() is null
     or not public._science_world_can_access_question(p_question_id) then
    return query select false, null::text;
    return;
  end if;

  select q.correct_answer, q.solution
    into v_correct_answer, v_solution
  from public.questions q
  where q.id = p_question_id
    and q.review_status in ('published', 'approved');

  if not found then
    return query select false, null::text;
    return;
  end if;

  return query
    select
      lower(btrim(coalesce(p_answer, ''))) =
        lower(btrim(coalesce(v_correct_answer, ''))),
      case
        when lower(btrim(coalesce(p_answer, ''))) =
             lower(btrim(coalesce(v_correct_answer, '')))
        then v_solution
        else null::text
      end;
end;
$function$;
revoke all on function public.check_question_answer(uuid, text) from public, anon;
grant execute on function public.check_question_answer(uuid, text) to authenticated;

commit;
