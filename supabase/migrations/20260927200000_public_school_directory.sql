-- Allow the student sign-up screen (used before the account exists, i.e.
-- while still unauthenticated) to show the list of active schools.
-- Apply in the Supabase SQL Editor while signed in as a project administrator.
--
-- The "schools" table itself stays restricted to authenticated users
-- (policy "schools_select_authenticated"); this adds a narrow,
-- security-definer read-only directory (id + name only) that anonymous
-- and authenticated clients can call safely.

create or replace function public.list_public_schools()
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select s.id, s.name
  from public.schools s
  where s.active
  order by s.name;
$$;

revoke all on function public.list_public_schools() from public;
grant execute on function public.list_public_schools() to anon, authenticated;
