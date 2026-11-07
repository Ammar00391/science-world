-- Science World V25 / 2026-11-07
-- Quota update requested for the 40-question lesson bank:
-- Free: first 6 free questions per lesson.
-- Silver: first 6 free + first 9 paid questions (15 total) per lesson.
-- Gold: every approved/published question per lesson.
-- This migration only changes access limits; it does not publish draft questions.
begin;

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
    select case
      when t.tier = 'gold' then true
      when q.is_paid = false then q.lesson_position <= 6
      when t.tier = 'silver' then q.lesson_position <= 9
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
      or (q.is_paid = true and t.tier = 'silver' and q.lesson_position <= 9)
    )
  order by q.created_at asc, q.id asc;
$function$;
revoke all on function public.get_questions(text, text, text, text) from public, anon;
grant execute on function public.get_questions(text, text, text, text) to authenticated;

commit;
