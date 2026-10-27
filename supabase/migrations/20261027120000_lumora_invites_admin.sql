-- Invite codes and the admin role for Lumora.
--
-- Sign-up needs a one-time invite code, checked here on the server: the
-- trigger that creates a new user's profile refuses the account when the
-- code (sent as user metadata `invite_code`) is missing, unknown or used,
-- which rolls the whole sign-up back. A used code is marked at once, so one
-- code makes one account. Existing accounts are untouched, and signing in
-- never asks for a code.
--
-- The admin role lives in `auth.users.raw_app_meta_data.role`, which only
-- the server can write. Codes are made and listed through two functions
-- that check that role; the table itself has no policy for the app at all.

create table public.invite_codes (
  code text primary key check (code ~ '^[A-Z2-9]{8}$'),
  note text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  used_by uuid references auth.users (id) on delete set null,
  used_at timestamptz
);

alter table public.invite_codes enable row level security;
-- No policies: nobody reads or writes the table directly.

-- `LUMO-7K3P` / `lumo 7k3p` -> `LUMO7K3P`.
create function public.normalize_invite_code(raw text)
returns text
language sql
immutable
set search_path = ''
as $$
  select upper(regexp_replace(coalesce(raw, ''), '[^A-Za-z0-9]', '', 'g'));
$$;

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select u.raw_app_meta_data ->> 'role' = 'admin'
       from auth.users u
      where u.id = (select auth.uid())),
    false);
$$;

-- Whether a code would be accepted, so the sign-up form can say so before
-- the account is attempted. Says nothing else about the code.
create function public.invite_code_valid(code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.invite_codes c
     where c.code = public.normalize_invite_code(invite_code_valid.code)
       and c.used_by is null);
$$;

create function public.create_invite_codes(how_many integer default 1, note text default null)
returns table (code text, created_at timestamptz)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  made integer := 0;
  candidate text;
  bytes bytea;
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
  if how_many < 1 or how_many > 50 then
    raise exception 'how_many must be 1..50';
  end if;
  while made < how_many loop
    bytes := extensions.gen_random_bytes(8);
    candidate := '';
    for i in 0..7 loop
      candidate := candidate || substr(alphabet, (get_byte(bytes, i) % length(alphabet)) + 1, 1);
    end loop;
    begin
      insert into public.invite_codes (code, note, created_by)
      values (candidate, create_invite_codes.note, (select auth.uid()));
      made := made + 1;
      code := candidate;
      created_at := now();
      return next;
    exception when unique_violation then
      -- Drawn twice; draw again.
    end;
  end loop;
end;
$$;

create function public.list_invite_codes()
returns table (code text, note text, created_at timestamptz, used_at timestamptz, used_by_email text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
  return query
    select c.code, c.note, c.created_at, c.used_at, u.email::text
      from public.invite_codes c
      left join auth.users u on u.id = c.used_by
     order by c.created_at desc;
end;
$$;

-- The existing profile trigger, now also the invite check.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  wanted text := public.normalize_invite_code(new.raw_user_meta_data ->> 'invite_code');
  taken text;
begin
  update public.invite_codes
     set used_by = new.id, used_at = now()
   where code = wanted and used_by is null
  returning code into taken;
  if taken is null then
    raise exception 'invalid invite code' using errcode = 'P0001';
  end if;

  insert into public.profiles (id, display_name)
  values (new.id, split_part(new.email, '@', 1));
  return new;
end;
$$;

revoke all on function public.is_admin() from public, anon;
revoke all on function public.create_invite_codes(integer, text) from public, anon;
revoke all on function public.list_invite_codes() from public, anon;
revoke all on function public.invite_code_valid(text) from public;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.create_invite_codes(integer, text) to authenticated;
grant execute on function public.list_invite_codes() to authenticated;
grant execute on function public.invite_code_valid(text) to anon, authenticated;
