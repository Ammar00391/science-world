-- Science World V20: secure question retrieval and answer checking.
-- Safe to run on the existing project. Does not drop tables or question data.
begin;

-- Block direct client reads of the question table and its version snapshots.
-- Version JSON may also contain answer keys and solutions.
revoke select on table public.questions from anon, authenticated;
revoke select on table public.question_versions, public.question_tags from anon, authenticated;
drop policy if exists questions_select_entitled on public.questions;
drop policy if exists question_versions_select_entitled on public.question_versions;
drop policy if exists question_tags_select_entitled on public.question_tags;

-- Keep the existing 4-argument RPC signature used by the deployed app setup,
-- but return only non-sensitive question columns.
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
  select q.id, q.grade, q.subject, q.chapter, q.lesson, q.school_year,
         q.difficulty, q.type, q.source, q.review_status, q.is_paid,
         q.question_text, q.options, q.created_at, q.updated_at
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
        select 1 from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status = 'premium'
          and (s.expires_at is null or s.expires_at > now())
      )
    );
$function$;
revoke all on function public.get_questions(text, text, text, text) from public, anon;
grant execute on function public.get_questions(text, text, text, text) to authenticated;

create or replace function public.get_question_by_id(p_question_id uuid)
returns table (
  id uuid, grade text, subject text, chapter text, lesson text,
  school_year text, difficulty text, type text, source text,
  review_status text, is_paid boolean, question_text text, options jsonb,
  created_at timestamptz, updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select q.id, q.grade, q.subject, q.chapter, q.lesson, q.school_year,
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
    select 1 from public.subscriptions s
    where s.user_id = v_uid
      and s.status = 'premium'
      and (s.expires_at is null or s.expires_at > now())
  ) then
    return query select false, null::text;
    return;
  end if;

  v_is_correct := lower(btrim(coalesce(p_answer, ''))) =
                  lower(btrim(coalesce(v_correct_answer, '')));

  return query select v_is_correct,
    case when v_is_correct then v_solution else null::text end;
end;
$function$;
revoke all on function public.check_question_answer(uuid, text) from public, anon;
grant execute on function public.check_question_answer(uuid, text) to authenticated;

commit;
