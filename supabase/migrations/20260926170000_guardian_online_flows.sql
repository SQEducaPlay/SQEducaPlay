-- Safe, authenticated RPCs for guardian-managed child profiles and quiz sync.

create unique index if not exists student_profiles_username_ci
  on public.student_profiles (lower(username));

alter table public.quiz_sessions
  add column if not exists client_session_id uuid;

create unique index if not exists quiz_sessions_client_session_id
  on public.quiz_sessions (client_session_id)
  where client_session_id is not null;

create or replace function public.create_student_profile(
  p_username text,
  p_full_name text,
  p_nickname text,
  p_grade text,
  p_school_id uuid,
  p_consent_version text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_student_id uuid;
  student_status text;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid())
      and p.role in ('guardian', 'admin')
  ) then
    raise exception 'Guardian account required';
  end if;

  if p_school_id is not null and not exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ) then
    raise exception 'School enrollment must be approved by an authorized educator';
  end if;

  if p_username is null
    or p_username !~ '^[A-Za-z0-9._-]{3,20}$'
    or p_full_name is null
    or length(btrim(p_full_name)) not between 1 and 120
    or p_grade is null
    or length(btrim(p_grade)) not between 1 and 80
    or p_consent_version is null
    or length(btrim(p_consent_version)) not between 1 and 40 then
    raise exception 'Invalid student profile fields';
  end if;

  if exists (
    select 1 from public.student_profiles sp
    where lower(sp.username) = lower(btrim(p_username))
  ) then
    raise exception 'Student username is already in use';
  end if;

  if p_school_id is not null and not exists (
    select 1 from public.schools s
    where s.id = p_school_id and s.active
  ) then
    raise exception 'Selected school is unavailable';
  end if;

  student_status := case when p_school_id is null then 'active' else 'pending' end;

  insert into public.student_profiles (
    guardian_id, username, full_name, nickname, grade, school_id, status
  )
  values (
    (select auth.uid()),
    lower(btrim(p_username)),
    btrim(p_full_name),
    nullif(btrim(p_nickname), ''),
    btrim(p_grade),
    p_school_id,
    student_status
  )
  returning id into new_student_id;

  insert into public.consent_records (
    student_id, guardian_id, consent_version
  )
  values (new_student_id, (select auth.uid()), btrim(p_consent_version));

  return new_student_id;
end;
$$;

create or replace function public.record_quiz_session(
  p_student_id uuid,
  p_client_session_id uuid,
  p_subject text,
  p_grade text,
  p_topic text,
  p_score integer,
  p_stars integer,
  p_correct_answers integer,
  p_total_questions integer,
  p_duration_seconds integer,
  p_completed_at timestamptz,
  p_attempts jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_session_id uuid;
  attempt jsonb;
begin
  if (select auth.uid()) is null
    or p_student_id is null
    or p_client_session_id is null then
    raise exception 'Authentication and session identifiers are required';
  end if;

  if not exists (
    select 1 from public.student_profiles sp
    where sp.id = p_student_id
      and sp.guardian_id = (select auth.uid())
      and sp.status = 'active'
  ) then
    raise exception 'Active student profile not owned by this guardian';
  end if;

  if p_subject is null or length(btrim(p_subject)) not between 1 and 80
    or p_grade is null or length(btrim(p_grade)) not between 1 and 80
    or p_score not between 0 and 1000000
    or p_stars not between 0 and 100000
    or p_total_questions not between 1 and 100
    or p_correct_answers not between 0 and p_total_questions
    or (p_duration_seconds is not null and p_duration_seconds < 0)
    or jsonb_typeof(coalesce(p_attempts, '[]'::jsonb)) <> 'array'
    or jsonb_array_length(coalesce(p_attempts, '[]'::jsonb)) > 100 then
    raise exception 'Invalid quiz session values';
  end if;

  insert into public.quiz_sessions (
    student_id, client_session_id, subject, grade, topic, score, stars,
    correct_answers, total_questions, duration_seconds, completed_at
  )
  values (
    p_student_id, p_client_session_id, btrim(p_subject), btrim(p_grade),
    nullif(btrim(p_topic), ''), p_score, p_stars, p_correct_answers,
    p_total_questions, p_duration_seconds, coalesce(p_completed_at, now())
  )
  on conflict (client_session_id) where client_session_id is not null
  do nothing
  returning id into new_session_id;

  if new_session_id is null then
    select qs.id into new_session_id
    from public.quiz_sessions qs
    where qs.client_session_id = p_client_session_id
      and qs.student_id = p_student_id;
    if new_session_id is null then
      raise exception 'Session identifier is already used by another profile';
    end if;
    return new_session_id;
  end if;

  if exists (
    select 1
    from jsonb_array_elements(coalesce(p_attempts, '[]'::jsonb)) as item(value)
    group by coalesce((value ->> 'question_order')::integer, 0)
    having count(*) > 1
  ) then
    raise exception 'Question order must be unique within a quiz session';
  end if;

  for attempt in
    select value from jsonb_array_elements(coalesce(p_attempts, '[]'::jsonb))
  loop
    if jsonb_typeof(attempt) <> 'object'
      or length(coalesce(attempt ->> 'question', '')) > 1000
      or length(coalesce(attempt ->> 'selected_answer', '')) > 1000
      or length(coalesce(attempt ->> 'correct_answer', '')) > 1000
      or coalesce((attempt ->> 'question_order')::integer, 0) not between 0 and 99 then
      raise exception 'Quiz answer fields are too long';
    end if;

    insert into public.question_attempts (
      quiz_session_id, student_id, subject, grade, topic, question,
      selected_answer, correct_answer, is_correct, question_order
    )
    values (
      new_session_id,
      p_student_id,
      btrim(p_subject),
      btrim(p_grade),
      nullif(btrim(p_topic), ''),
      coalesce(attempt ->> 'question', ''),
      coalesce(attempt ->> 'selected_answer', ''),
      coalesce(attempt ->> 'correct_answer', ''),
      coalesce((attempt ->> 'is_correct')::boolean, false),
      coalesce((attempt ->> 'question_order')::integer, 0)
    );
  end loop;

  if p_total_questions > 0 and p_correct_answers * 100 >= p_total_questions * 70
    and p_topic is not null and length(btrim(p_topic)) > 0 then
    insert into public.student_progress (
      student_id, subject, grade, topic, completed, completed_at, updated_at
    )
    values (
      p_student_id, btrim(p_subject), btrim(p_grade), btrim(p_topic),
      true, now(), now()
    )
    on conflict (student_id, subject, grade, topic)
    do update set
      completed = true,
      completed_at = coalesce(public.student_progress.completed_at, excluded.completed_at),
      updated_at = excluded.updated_at;
  end if;

  return new_session_id;
end;
$$;

create or replace function public.record_history_migration_consent(
  p_student_id uuid,
  p_consent_version text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null
    or not exists (
      select 1 from public.student_profiles sp
      where sp.id = p_student_id
        and sp.guardian_id = (select auth.uid())
        and sp.status = 'active'
    ) then
    raise exception 'Active student profile not owned by this guardian';
  end if;
  if p_consent_version is null or length(btrim(p_consent_version)) not between 1 and 80 then
    raise exception 'Invalid consent version';
  end if;

  insert into public.consent_records (student_id, guardian_id, consent_version)
  values (
    p_student_id,
    (select auth.uid()),
    btrim(p_consent_version) || ':history-import'
  );
end;
$$;

revoke all on function public.create_student_profile(text, text, text, text, uuid, text) from public;
revoke all on function public.record_quiz_session(uuid, uuid, text, text, text, integer, integer, integer, integer, integer, timestamptz, jsonb) from public;
revoke all on function public.record_history_migration_consent(uuid, text) from public;
grant execute on function public.create_student_profile(text, text, text, text, uuid, text) to authenticated;
grant execute on function public.record_quiz_session(uuid, uuid, text, text, text, integer, integer, integer, integer, integer, timestamptz, jsonb) to authenticated;
grant execute on function public.record_history_migration_consent(uuid, text) to authenticated;

revoke insert on public.student_profiles from authenticated;
revoke insert on public.quiz_sessions from authenticated;
revoke insert on public.question_attempts from authenticated;
revoke insert on public.consent_records from authenticated;
revoke update on public.profiles from authenticated;
grant update (full_name) on public.profiles to authenticated;
