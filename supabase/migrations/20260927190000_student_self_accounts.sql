-- Allow students to create and use their own account (email/password),
-- independent from a guardian, plus a short code guardians can use to
-- link (view-only) to a student's progress afterwards.

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('guardian', 'teacher', 'school_admin', 'admin', 'student'));

create or replace function public.create_guardian_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text;
begin
  requested_role := case
    when new.raw_user_meta_data ->> 'account_type' = 'student' then 'student'
    else 'guardian'
  end;
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    requested_role
  );
  return new;
end;
$$;

alter table public.student_profiles alter column guardian_id drop not null;

alter table public.student_profiles
  add column if not exists owner_user_id uuid unique references auth.users (id) on delete cascade;

alter table public.student_profiles
  add column if not exists student_code text unique;

alter table public.student_profiles
  add constraint student_profiles_owner_check
  check (guardian_id is not null or owner_user_id is not null);

create table if not exists public.guardian_student_links (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid not null references public.student_profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (guardian_id, student_id)
);

alter table public.guardian_student_links enable row level security;
revoke all on public.guardian_student_links from public, anon, authenticated;

create policy "guardian_links_select_own"
  on public.guardian_student_links for select to authenticated
  using (guardian_id = (select auth.uid()) or public.is_platform_admin());

grant select on public.guardian_student_links to authenticated;

create or replace function public.generate_unique_student_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  candidate text;
  attempts int := 0;
begin
  loop
    candidate := 'ALU-' || upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 6));
    exit when not exists (
      select 1 from public.student_profiles sp where sp.student_code = candidate
    );
    attempts := attempts + 1;
    if attempts > 20 then
      raise exception 'Nao foi possivel gerar um codigo unico de aluno';
    end if;
  end loop;
  return candidate;
end;
$$;

create or replace function public.create_self_student_profile(
  p_full_name text,
  p_grade text,
  p_school_id uuid
)
returns table (student_id uuid, student_code text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_student_id uuid;
  new_code text;
  new_username text;
  current_role text;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;

  select p.role into current_role
  from public.profiles p
  where p.id = (select auth.uid());

  if current_role is distinct from 'student' then
    raise exception 'Somente contas de aluno podem criar um perfil de aluno';
  end if;

  if exists (
    select 1 from public.student_profiles sp
    where sp.owner_user_id = (select auth.uid())
  ) then
    raise exception 'Esta conta ja possui um perfil de aluno';
  end if;

  if p_full_name is null or length(btrim(p_full_name)) not between 1 and 120 then
    raise exception 'Informe um nome valido';
  end if;
  if p_grade is null or length(btrim(p_grade)) not between 1 and 80 then
    raise exception 'Informe o ano escolar';
  end if;
  if p_school_id is not null and not exists (
    select 1 from public.schools s where s.id = p_school_id and s.active
  ) then
    raise exception 'Escola selecionada indisponivel';
  end if;

  new_code := public.generate_unique_student_code();
  new_username := 'aluno-' || lower(replace(new_code, 'ALU-', ''));

  insert into public.student_profiles (
    owner_user_id, guardian_id, username, full_name, grade, school_id,
    status, student_code
  )
  values (
    (select auth.uid()), null, new_username, btrim(p_full_name), btrim(p_grade),
    p_school_id, 'active', new_code
  )
  returning id into new_student_id;

  return query select new_student_id, new_code;
end;
$$;

create or replace function public.link_guardian_to_student(p_student_code text)
returns table (student_id uuid, full_name text, grade text, school_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  matched public.student_profiles%rowtype;
  school_name_val text;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role in ('guardian', 'admin')
  ) then
    raise exception 'Somente contas de responsavel podem vincular um aluno';
  end if;

  if p_student_code is null or length(btrim(p_student_code)) not between 4 and 40 then
    raise exception 'Informe um codigo de aluno valido';
  end if;

  select sp.* into matched
  from public.student_profiles sp
  where sp.student_code = upper(btrim(p_student_code));

  if not found then
    raise exception 'Codigo de aluno nao encontrado';
  end if;

  if matched.owner_user_id is null then
    raise exception 'Este perfil de aluno nao pode ser vinculado por codigo';
  end if;

  if matched.school_id is not null then
    select s.name into school_name_val from public.schools s where s.id = matched.school_id;
  end if;

  insert into public.guardian_student_links (guardian_id, student_id)
  values ((select auth.uid()), matched.id)
  on conflict (guardian_id, student_id) do nothing;

  return query select matched.id, matched.full_name, matched.grade, school_name_val;
end;
$$;

create or replace function public.list_linked_students()
returns table (
  student_id uuid,
  full_name text,
  grade text,
  school_name text,
  status text,
  student_code text
)
language sql
stable
security definer
set search_path = ''
as $$
  select sp.id, sp.full_name, sp.grade, s.name, sp.status, sp.student_code
  from public.guardian_student_links gsl
  join public.student_profiles sp on sp.id = gsl.student_id
  left join public.schools s on s.id = sp.school_id
  where gsl.guardian_id = (select auth.uid())
  order by sp.full_name;
$$;

revoke all on function public.generate_unique_student_code() from public, anon, authenticated;
revoke all on function public.create_self_student_profile(text, text, uuid) from public, anon;
revoke all on function public.link_guardian_to_student(text) from public, anon;
revoke all on function public.list_linked_students() from public, anon;
grant execute on function public.create_self_student_profile(text, text, uuid) to authenticated;
grant execute on function public.link_guardian_to_student(text) to authenticated;
grant execute on function public.list_linked_students() to authenticated;

create or replace function public.can_access_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.student_profiles sp
    where sp.id = p_student_id
      and (
        sp.guardian_id = (select auth.uid())
        or sp.owner_user_id = (select auth.uid())
        or public.is_platform_admin()
        or exists (
          select 1 from public.guardian_student_links gsl
          where gsl.student_id = sp.id
            and gsl.guardian_id = (select auth.uid())
        )
        or exists (
          select 1
          from public.student_enrollments se
          join public.classrooms c on c.id = se.classroom_id
          join public.school_memberships sm
            on sm.school_id = c.school_id
           and sm.user_id = (select auth.uid())
          where se.student_id = sp.id
            and se.active
            and c.active
            and sm.status = 'active'
        )
      )
  );
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
      and (sp.guardian_id = (select auth.uid()) or sp.owner_user_id = (select auth.uid()))
      and sp.status = 'active'
  ) then
    raise exception 'Active student profile not owned by this guardian or student';
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
        and (sp.guardian_id = (select auth.uid()) or sp.owner_user_id = (select auth.uid()))
        and sp.status = 'active'
    ) then
    raise exception 'Active student profile not owned by this guardian or student';
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

drop policy if exists "quiz_sessions_guardian_insert" on public.quiz_sessions;
create policy "quiz_sessions_guardian_insert"
  on public.quiz_sessions for insert to authenticated
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and (sp.guardian_id = (select auth.uid()) or sp.owner_user_id = (select auth.uid()))
        and sp.status = 'active'
    )
  );

drop policy if exists "question_attempts_guardian_insert" on public.question_attempts;
create policy "question_attempts_guardian_insert"
  on public.question_attempts for insert to authenticated
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and (sp.guardian_id = (select auth.uid()) or sp.owner_user_id = (select auth.uid()))
        and sp.status = 'active'
    )
    and exists (
      select 1 from public.quiz_sessions qs
      where qs.id = quiz_session_id and qs.student_id = student_id
    )
  );

drop policy if exists "progress_guardian_insert" on public.student_progress;
create policy "progress_guardian_insert"
  on public.student_progress for insert to authenticated
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and (sp.guardian_id = (select auth.uid()) or sp.owner_user_id = (select auth.uid()))
        and sp.status = 'active'
    )
  );

drop policy if exists "progress_guardian_update" on public.student_progress;
create policy "progress_guardian_update"
  on public.student_progress for update to authenticated
  using (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and (sp.guardian_id = (select auth.uid()) or sp.owner_user_id = (select auth.uid()))
        and sp.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and (sp.guardian_id = (select auth.uid()) or sp.owner_user_id = (select auth.uid()))
    )
  );
