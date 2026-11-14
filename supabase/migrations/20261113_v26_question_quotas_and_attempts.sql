-- V26: apply the current per-lesson question policy and retain answer attempts.
-- Free: first 3 free questions.
-- Silver: first 3 free + first 3 paid questions (6 total).
-- Gold: first 40 reviewed questions in a lesson.
-- This migration preserves existing questions, subscriptions, and exam history.
begin;

create table if not exists public.question_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete restrict,
  selected_answer text,
  is_correct boolean not null default false,
  is_skipped boolean not null default false,
  created_at timestamptz not null default now(),
  constraint question_attempts_skip_answer_chk
    check (not is_skipped or selected_answer is null)
);

create index if not exists question_attempts_user_time_idx
  on public.question_attempts(user_id, created_at desc);
create index if not exists question_attempts_user_question_idx
  on public.question_attempts(user_id, question_id, created_at desc);

alter table public.question_attempts enable row level security;
drop policy if exists question_attempts_select_own on public.question_attempts;
create policy question_attempts_select_own on public.question_attempts
  for select to authenticated using (auth.uid() = user_id);
revoke all on table public.question_attempts from public, anon, authenticated;
grant select on public.question_attempts to authenticated;

-- Questions remain inaccessible through direct table reads. Every student RPC
-- below applies the same server-side entitlement and active-subscription check.
revoke all on table public.questions from public, anon, authenticated;

create or replace function public._science_world_can_access_question(
  p_question_id uuid
)
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
      ) as group_position,
      row_number() over (
        partition by q.grade, q.subject, coalesce(q.chapter, ''),
                     coalesce(q.lesson, '')
        order by q.created_at asc, q.id asc
      ) as lesson_position
    from public.questions q
    where q.review_status in ('approved', 'published')
  ),
  user_tier as (
    select coalesce((
      select lower(s.tier)
      from public.subscriptions s
      where s.user_id = auth.uid()
        and s.status = 'premium'
        and (s.starts_at is null or s.starts_at <= now())
        and (s.expires_at is null or s.expires_at > now())
      limit 1
    ), 'free') as tier
  )
  select coalesce((
    select case
      when t.tier = 'gold' then q.lesson_position <= 40
      when q.is_paid = false then q.group_position <= 3
      when t.tier = 'silver' then q.group_position <= 3
      else false
    end
    from ranked_questions q
    cross join user_tier t
    where q.id = p_question_id
  ), false);
$function$;
revoke all on function public._science_world_can_access_question(uuid)
  from public, anon, authenticated;

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
    select coalesce((
      select lower(s.tier)
      from public.subscriptions s
      where s.user_id = auth.uid()
        and s.status = 'premium'
        and (s.starts_at is null or s.starts_at <= now())
        and (s.expires_at is null or s.expires_at > now())
      limit 1
    ), 'free') as tier
  ),
  ranked_questions as (
    select
      q.*,
      row_number() over (
        partition by q.grade, q.subject, coalesce(q.chapter, ''),
                     coalesce(q.lesson, ''), q.is_paid
        order by q.created_at asc, q.id asc
      ) as group_position,
      row_number() over (
        partition by q.grade, q.subject, coalesce(q.chapter, ''),
                     coalesce(q.lesson, '')
        order by q.created_at asc, q.id asc
      ) as lesson_position
    from public.questions q
    where auth.uid() is not null
      and q.review_status in ('approved', 'published')
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
      (t.tier = 'gold' and q.lesson_position <= 40)
      or (q.is_paid = false and q.group_position <= 3)
      or (q.is_paid = true and t.tier = 'silver' and q.group_position <= 3)
    )
  order by q.created_at asc, q.id asc;
$function$;
revoke all on function public.get_questions(text, text, text, text)
  from public, anon;
grant execute on function public.get_questions(text, text, text, text)
  to authenticated;

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
    and q.review_status in ('approved', 'published')
    and public._science_world_can_access_question(q.id);
$function$;
revoke all on function public.get_question_by_id(uuid) from public, anon;
grant execute on function public.get_question_by_id(uuid) to authenticated;

create or replace function public.reveal_question_answer(p_question_id uuid)
returns table (correct_answer text, solution text)
language sql
stable
security definer
set search_path = ''
as $function$
  select q.correct_answer, q.solution
  from public.questions q
  where auth.uid() is not null
    and q.id = p_question_id
    and q.review_status in ('approved', 'published')
    and public._science_world_can_access_question(q.id)
    and exists (
      select 1
      from public.subscriptions s
      where s.user_id = auth.uid()
        and s.status = 'premium'
        and lower(s.tier) in ('silver', 'gold')
        and (s.starts_at is null or s.starts_at <= now())
        and (s.expires_at is null or s.expires_at > now())
    );
$function$;
revoke all on function public.reveal_question_answer(uuid) from public, anon;
grant execute on function public.reveal_question_answer(uuid) to authenticated;

create or replace function public.record_question_attempt(
  p_question_id uuid,
  p_selected_answer text default null,
  p_is_skipped boolean default false
)
returns table (attempt_id uuid, is_correct boolean, solution text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_correct_answer text;
  v_solution text;
  v_tier text := 'free';
  v_is_correct boolean := false;
  v_attempt_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_is_skipped and nullif(btrim(coalesce(p_selected_answer, '')), '') is not null then
    raise exception 'A skipped attempt cannot include an answer'
      using errcode = '22023';
  end if;
  if not p_is_skipped and nullif(btrim(coalesce(p_selected_answer, '')), '') is null then
    raise exception 'An answer is required unless the question is skipped'
      using errcode = '22023';
  end if;
  if not public._science_world_can_access_question(p_question_id) then
    raise exception 'Question is not available for this account'
      using errcode = '42501';
  end if;

  select q.correct_answer, q.solution
    into v_correct_answer, v_solution
  from public.questions q
  where q.id = p_question_id
    and q.review_status in ('approved', 'published');

  if not found then
    raise exception 'Question not found' using errcode = 'P0002';
  end if;

  if not p_is_skipped then
    v_is_correct :=
      lower(btrim(coalesce(p_selected_answer, ''))) =
      lower(btrim(coalesce(v_correct_answer, '')));
  end if;

  select lower(s.tier)
    into v_tier
  from public.subscriptions s
  where s.user_id = v_user_id
    and s.status = 'premium'
    and (s.starts_at is null or s.starts_at <= now())
    and (s.expires_at is null or s.expires_at > now())
  limit 1;
  v_tier := coalesce(v_tier, 'free');

  insert into public.question_attempts (
    user_id, question_id, selected_answer, is_correct, is_skipped
  ) values (
    v_user_id,
    p_question_id,
    case when p_is_skipped then null else btrim(p_selected_answer) end,
    v_is_correct,
    p_is_skipped
  )
  returning id into v_attempt_id;

  return query
    select v_attempt_id, v_is_correct,
      case when v_is_correct and v_tier in ('silver', 'gold')
        then v_solution else null::text end;
end;
$function$;
revoke all on function public.record_question_attempt(uuid, text, boolean)
  from public, anon;
grant execute on function public.record_question_attempt(uuid, text, boolean)
  to authenticated;

create or replace function public.check_question_answer(
  p_question_id uuid,
  p_answer text
)
returns table (is_correct boolean, solution text)
language plpgsql
security definer
set search_path = ''
as $function$
begin
  return query
    select attempt.is_correct, attempt.solution
    from public.record_question_attempt(p_question_id, p_answer, false) attempt;
end;
$function$;
revoke all on function public.check_question_answer(uuid, text) from public, anon;
grant execute on function public.check_question_answer(uuid, text) to authenticated;

commit;
