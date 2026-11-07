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
