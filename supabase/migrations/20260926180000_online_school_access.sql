-- Restricted school setup, educator invitations and pending-student approval.

create table public.teacher_invites (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  email text not null,
  token_hash bytea not null unique,
  expires_at timestamptz not null,
  created_by uuid not null references public.profiles (id) on delete restrict,
  used_by uuid references public.profiles (id) on delete set null,
  used_at timestamptz,
  created_at timestamptz not null default now(),
  check (email = lower(btrim(email))),
  check ((used_by is null) = (used_at is null))
);

create index teacher_invites_school_created_idx
  on public.teacher_invites (school_id, created_at desc);

-- Guardians may request enrollment at an active school; the profile remains
-- pending until an authorized school educator assigns it to a classroom.
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
  values (
    new_student_id,
    (select auth.uid()),
    btrim(p_consent_version) ||
      case when p_school_id is null then '' else ':school-enrollment' end
  );

  return new_student_id;
end;
$$;

alter table public.teacher_invites enable row level security;
revoke all on public.teacher_invites from public, anon, authenticated;

create or replace function public.create_teacher_invite(
  p_school_id uuid,
  p_email text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  invite_token text;
begin
  if (select auth.uid()) is null or p_school_id is null
    or p_email is null
    or length(btrim(p_email)) > 254
    or btrim(p_email) !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' then
    raise exception 'Valid school, authenticated administrator, and email are required';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and (
        p.role = 'admin'
        or exists (
          select 1
          from public.school_memberships sm
          where sm.user_id = p.id
            and sm.school_id = p_school_id
            and sm.role = 'school_admin'
            and sm.status = 'active'
        )
      )
  ) then
    raise exception 'Only an authorized school administrator can issue educator invitations';
  end if;

  if not exists (
    select 1 from public.schools s
    where s.id = p_school_id and s.active
  ) then
    raise exception 'School is unavailable';
  end if;

  invite_token := 'SQ-' || upper(encode(extensions.gen_random_bytes(20), 'hex'));
  insert into public.teacher_invites (
    school_id, email, token_hash, expires_at, created_by
  )
  values (
    p_school_id,
    lower(btrim(p_email)),
    extensions.digest(invite_token, 'sha256'),
    now() + interval '14 days',
    (select auth.uid())
  );

  return invite_token;
end;
$$;

create or replace function public.redeem_teacher_invite(p_invite_token text)
returns table (school_id uuid, school_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := (select auth.uid());
  current_email text;
  invite public.teacher_invites%rowtype;
begin
  if current_user_id is null or p_invite_token is null
    or length(p_invite_token) not between 10 and 100 then
    raise exception 'Authenticated account and invitation code are required';
  end if;

  select lower(p.email) into current_email
  from public.profiles p
  where p.id = current_user_id;

  if current_email is null then
    raise exception 'Account profile is unavailable';
  end if;

  select ti.* into invite
  from public.teacher_invites ti
  where ti.token_hash = extensions.digest(upper(btrim(p_invite_token)), 'sha256')
  for update;

  if not found
    or invite.used_at is not null
    or invite.expires_at <= now()
    or invite.email <> current_email then
    raise exception 'Invitation is invalid, expired, already used, or belongs to another email';
  end if;

  if not exists (
    select 1 from public.schools s
    where s.id = invite.school_id and s.active
  ) then
    raise exception 'School is unavailable';
  end if;

  update public.profiles
  set role = 'teacher'
  where id = current_user_id
    and role in ('guardian', 'teacher');

  if not found then
    raise exception 'This account cannot be enrolled as an educator';
  end if;

  insert into public.school_memberships (user_id, school_id, role, status)
  values (current_user_id, invite.school_id, 'teacher', 'active')
  on conflict (user_id, school_id)
  do update set role = excluded.role, status = excluded.status;

  update public.teacher_invites
  set used_by = current_user_id, used_at = now()
  where id = invite.id and used_at is null;

  if not found then
    raise exception 'Invitation was already used';
  end if;

  return query
  select s.id, s.name
  from public.schools s
  where s.id = invite.school_id;
end;
$$;

create or replace function public.assign_school_administrator(
  p_school_id uuid,
  p_email text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_user_id uuid;
begin
  if (select auth.uid()) is null
    or not exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin'
    ) then
    raise exception 'Only a platform administrator can assign school administrators';
  end if;

  select p.id into target_user_id
  from public.profiles p
  where lower(p.email) = lower(btrim(p_email))
    and p.role in ('guardian', 'teacher', 'school_admin');
  if target_user_id is null then
    raise exception 'Create the school administrator account before assigning it';
  end if;

  if not exists (
    select 1 from public.schools s
    where s.id = p_school_id and s.active
  ) then
    raise exception 'School is unavailable';
  end if;

  update public.profiles set role = 'school_admin' where id = target_user_id;
  insert into public.school_memberships (user_id, school_id, role, status)
  values (target_user_id, p_school_id, 'school_admin', 'active')
  on conflict (user_id, school_id)
  do update set role = excluded.role, status = excluded.status;

  return target_user_id;
end;
$$;

-- The RPC above is the only authenticated path that can promote an educator.
create or replace function public.prevent_profile_role_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user = 'authenticated'
    and new.role is distinct from old.role then
    raise exception 'Profile roles can only be changed through an authorized invitation';
  end if;
  return new;
end;
$$;

create policy "school_staff_select_pending_students"
  on public.student_profiles for select to authenticated
  using (
    status = 'pending'
    and school_id is not null
    and exists (
      select 1 from public.school_memberships sm
      where sm.user_id = (select auth.uid())
        and sm.school_id = student_profiles.school_id
        and sm.role in ('teacher', 'school_admin')
        and sm.status = 'active'
    )
  );

create policy "school_admin_manage_classrooms"
  on public.classrooms for all to authenticated
  using (
    exists (
      select 1 from public.school_memberships sm
      where sm.user_id = (select auth.uid())
        and sm.school_id = classrooms.school_id
        and sm.role = 'school_admin'
        and sm.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from public.school_memberships sm
      where sm.user_id = (select auth.uid())
        and sm.school_id = classrooms.school_id
        and sm.role = 'school_admin'
        and sm.status = 'active'
    )
  );

revoke all on function public.create_teacher_invite(uuid, text) from public, anon;
revoke all on function public.redeem_teacher_invite(text) from public, anon;
revoke all on function public.assign_school_administrator(uuid, text) from public, anon;
grant execute on function public.create_teacher_invite(uuid, text) to authenticated;
grant execute on function public.redeem_teacher_invite(text) to authenticated;
grant execute on function public.assign_school_administrator(uuid, text) to authenticated;
