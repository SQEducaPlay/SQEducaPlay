-- SQEducaPlay initial hosted schema.
-- Apply in the Supabase SQL Editor while signed in as a project administrator.

create extension if not exists pgcrypto with schema extensions;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text not null default '',
  role text not null default 'guardian'
    check (role in ('guardian', 'teacher', 'school_admin', 'admin')),
  created_at timestamptz not null default now()
);

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.classrooms (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete restrict,
  grade text not null,
  name text not null,
  shift text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, grade, name, shift)
);

create table public.school_memberships (
  user_id uuid not null references public.profiles (id) on delete cascade,
  school_id uuid not null references public.schools (id) on delete cascade,
  role text not null check (role in ('teacher', 'school_admin')),
  status text not null default 'invited'
    check (status in ('invited', 'active', 'suspended')),
  login_alias text,
  created_at timestamptz not null default now(),
  primary key (user_id, school_id)
);

create table public.student_profiles (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null references public.profiles (id) on delete cascade,
  username text not null unique,
  full_name text not null,
  nickname text,
  grade text not null,
  school_id uuid references public.schools (id) on delete restrict,
  status text not null default 'pending'
    check (status in ('pending', 'active', 'suspended')),
  created_at timestamptz not null default now()
);

create table public.student_enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.student_profiles (id) on delete cascade,
  classroom_id uuid not null references public.classrooms (id) on delete restrict,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (student_id, classroom_id)
);

create table public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.student_profiles (id) on delete cascade,
  subject text not null,
  grade text not null,
  topic text,
  score integer not null default 0 check (score >= 0),
  stars integer not null default 0 check (stars >= 0),
  correct_answers integer not null default 0 check (correct_answers >= 0),
  total_questions integer not null default 0 check (total_questions >= 0),
  duration_seconds integer check (duration_seconds is null or duration_seconds >= 0),
  completed_at timestamptz not null default now(),
  check (correct_answers <= total_questions)
);

create table public.question_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_session_id uuid not null references public.quiz_sessions (id) on delete cascade,
  student_id uuid not null references public.student_profiles (id) on delete cascade,
  subject text not null,
  grade text not null,
  topic text,
  question text not null,
  selected_answer text not null,
  correct_answer text not null,
  is_correct boolean not null,
  question_order integer not null default 0 check (question_order >= 0),
  created_at timestamptz not null default now(),
  unique (quiz_session_id, question_order)
);

create table public.student_progress (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.student_profiles (id) on delete cascade,
  subject text not null,
  grade text not null,
  topic text not null,
  completed boolean not null default false,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (student_id, subject, grade, topic)
);

create table public.consent_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.student_profiles (id) on delete cascade,
  guardian_id uuid not null references public.profiles (id) on delete cascade,
  consent_version text not null,
  consented_at timestamptz not null default now(),
  withdrawn_at timestamptz
);

create index student_profiles_guardian_idx
  on public.student_profiles (guardian_id);
create index student_profiles_school_status_idx
  on public.student_profiles (school_id, status);
create index student_enrollments_classroom_idx
  on public.student_enrollments (classroom_id, active);
create index quiz_sessions_student_completed_idx
  on public.quiz_sessions (student_id, completed_at desc);
create index question_attempts_student_idx
  on public.question_attempts (student_id, created_at desc);
create index student_progress_student_idx
  on public.student_progress (student_id);
create index school_memberships_school_status_idx
  on public.school_memberships (school_id, status);

create or replace function public.create_guardian_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    'guardian'
  );
  return new;
end;
$$;

create trigger on_auth_user_created_sqeducaplay
  after insert on auth.users
  for each row execute function public.create_guardian_profile();

create or replace function public.prevent_profile_role_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and new.role is distinct from old.role then
    raise exception 'Profile roles can only be changed by a project administrator';
  end if;
  return new;
end;
$$;

create trigger protect_profile_role
  before update of role on public.profiles
  for each row execute function public.prevent_profile_role_change();

create or replace function public.protect_student_enrollment_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    if new.guardian_id is distinct from old.guardian_id
      or new.school_id is distinct from old.school_id then
      raise exception 'Guardian and school assignments cannot be changed by clients';
    end if;

    if new.status is distinct from old.status
      and not public.is_platform_admin()
      and not exists (
        select 1 from public.school_memberships sm
        where sm.user_id = (select auth.uid())
          and sm.school_id = old.school_id
          and sm.role in ('teacher', 'school_admin')
          and sm.status = 'active'
      ) then
      raise exception 'Only an authorized school educator can change student status';
    end if;
  end if;
  return new;
end;
$$;

create trigger protect_student_enrollment_fields
  before update of guardian_id, school_id, status on public.student_profiles
  for each row execute function public.protect_student_enrollment_fields();

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

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
        or public.is_platform_admin()
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

create or replace function public.approve_student(
  p_student_id uuid,
  p_classroom_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_school_id uuid;
begin
  select sp.school_id into target_school_id
  from public.student_profiles sp
  where sp.id = p_student_id and sp.status = 'pending';

  if target_school_id is null then
    raise exception 'Student is missing, already approved, or has no school';
  end if;

  if not exists (
    select 1 from public.classrooms c
    where c.id = p_classroom_id
      and c.school_id = target_school_id
      and c.active
  ) then
    raise exception 'Classroom does not belong to the student school';
  end if;

  if not exists (
    select 1 from public.school_memberships sm
    where sm.user_id = (select auth.uid())
      and sm.school_id = target_school_id
      and sm.role in ('teacher', 'school_admin')
      and sm.status = 'active'
  ) and not public.is_platform_admin() then
    raise exception 'Only an authorized school educator can approve this student';
  end if;

  update public.student_profiles
  set status = 'active'
  where id = p_student_id;

  insert into public.student_enrollments (student_id, classroom_id, active)
  values (p_student_id, p_classroom_id, true)
  on conflict (student_id, classroom_id)
  do update set active = excluded.active;
end;
$$;

revoke all on function public.is_platform_admin() from public;
revoke all on function public.can_access_student(uuid) from public;
revoke all on function public.approve_student(uuid, uuid) from public;
revoke all on function public.create_guardian_profile() from public;
revoke all on function public.prevent_profile_role_change() from public;
revoke all on function public.protect_student_enrollment_fields() from public;
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.can_access_student(uuid) to authenticated;
grant execute on function public.approve_student(uuid, uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.schools enable row level security;
alter table public.classrooms enable row level security;
alter table public.school_memberships enable row level security;
alter table public.student_profiles enable row level security;
alter table public.student_enrollments enable row level security;
alter table public.quiz_sessions enable row level security;
alter table public.question_attempts enable row level security;
alter table public.student_progress enable row level security;
alter table public.consent_records enable row level security;

create policy "profiles_select_self_or_admin"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or public.is_platform_admin());
create policy "profiles_update_self_or_admin"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()) or public.is_platform_admin())
  with check (id = (select auth.uid()) or public.is_platform_admin());

create policy "schools_select_authenticated"
  on public.schools for select to authenticated using (active or public.is_platform_admin());
create policy "schools_admin_manage"
  on public.schools for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

create policy "classrooms_select_authenticated"
  on public.classrooms for select to authenticated
  using (active or public.is_platform_admin());
create policy "classrooms_admin_manage"
  on public.classrooms for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

create policy "memberships_select_self_or_admin"
  on public.school_memberships for select to authenticated
  using (user_id = (select auth.uid()) or public.is_platform_admin());
create policy "memberships_admin_manage"
  on public.school_memberships for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

create policy "students_select_authorized"
  on public.student_profiles for select to authenticated
  using (public.can_access_student(id));
create policy "students_guardian_create"
  on public.student_profiles for insert to authenticated
  with check (
    guardian_id = (select auth.uid())
    and status = 'pending'
    and (school_id is null or exists (
      select 1 from public.schools s where s.id = school_id and s.active
    ))
  );
create policy "students_guardian_update_or_admin"
  on public.student_profiles for update to authenticated
  using (guardian_id = (select auth.uid()) or public.is_platform_admin())
  with check (guardian_id = (select auth.uid()) or public.is_platform_admin());
create policy "students_admin_delete"
  on public.student_profiles for delete to authenticated
  using (public.is_platform_admin());

create policy "enrollments_select_authorized"
  on public.student_enrollments for select to authenticated
  using (public.can_access_student(student_id));
create policy "enrollments_admin_manage"
  on public.student_enrollments for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

create policy "quiz_sessions_select_authorized"
  on public.quiz_sessions for select to authenticated
  using (public.can_access_student(student_id));
create policy "quiz_sessions_guardian_insert"
  on public.quiz_sessions for insert to authenticated
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and sp.guardian_id = (select auth.uid())
        and sp.status = 'active'
    )
  );

create policy "question_attempts_select_authorized"
  on public.question_attempts for select to authenticated
  using (public.can_access_student(student_id));
create policy "question_attempts_guardian_insert"
  on public.question_attempts for insert to authenticated
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and sp.guardian_id = (select auth.uid())
        and sp.status = 'active'
    )
    and exists (
      select 1 from public.quiz_sessions qs
      where qs.id = quiz_session_id and qs.student_id = student_id
    )
  );

create policy "progress_select_authorized"
  on public.student_progress for select to authenticated
  using (public.can_access_student(student_id));
create policy "progress_guardian_insert"
  on public.student_progress for insert to authenticated
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and sp.guardian_id = (select auth.uid())
        and sp.status = 'active'
    )
  );
create policy "progress_guardian_update"
  on public.student_progress for update to authenticated
  using (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id
        and sp.guardian_id = (select auth.uid())
        and sp.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id and sp.guardian_id = (select auth.uid())
    )
  );

create policy "consents_guardian_select"
  on public.consent_records for select to authenticated
  using (guardian_id = (select auth.uid()) or public.is_platform_admin());
create policy "consents_guardian_insert"
  on public.consent_records for insert to authenticated
  with check (
    guardian_id = (select auth.uid())
    and exists (
      select 1 from public.student_profiles sp
      where sp.id = student_id and sp.guardian_id = (select auth.uid())
    )
  );

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete
  on public.schools, public.classrooms, public.school_memberships to authenticated;
grant select, insert, update, delete on public.student_profiles to authenticated;
grant select, insert, delete on public.student_enrollments to authenticated;
grant select, insert on public.quiz_sessions, public.question_attempts to authenticated;
grant select, insert, update on public.student_progress to authenticated;
grant select, insert on public.consent_records to authenticated;
