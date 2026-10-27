-- Google / Facebook sign-in, still invite-only.
--
-- An email sign-up spends its invite code as it is created, as before. A
-- Google or Facebook sign-up cannot carry a code, so the account is created
-- un-invited and the viewer redeems a code afterwards (redeem_invite). The
-- flag lives in app_metadata, which only the server can write - not in
-- profiles, whose own row each user may edit.

-- Every account so far was created with an invite.
update auth.users
   set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
                           || '{"invited": true}'::jsonb
 where not coalesce(raw_app_meta_data, '{}'::jsonb) ? 'invited';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  provider text := coalesce(new.raw_app_meta_data ->> 'provider', 'email');
  wanted text := public.normalize_invite_code(new.raw_user_meta_data ->> 'invite_code');
  taken text;
begin
  if provider = 'email' then
    update public.invite_codes
       set used_by = new.id, used_at = now()
     where code = wanted and used_by is null
    returning code into taken;
    if taken is null then
      raise exception 'invalid invite code' using errcode = 'P0001';
    end if;
  end if;

  update auth.users
     set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
                             || jsonb_build_object('invited', provider = 'email')
   where id = new.id;

  insert into public.profiles (id, display_name)
  values (new.id, split_part(coalesce(new.email, ''), '@', 1));
  return new;
end;
$$;

-- Spends [code] for the signed-in account. True when the account is (now)
-- invited, false when the code is wrong or used.
create or replace function public.redeem_invite(code text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  taken text;
begin
  if me is null then
    return false;
  end if;
  if exists (
    select 1 from auth.users u
     where u.id = me and (u.raw_app_meta_data ->> 'invited')::boolean
  ) then
    return true;
  end if;

  update public.invite_codes c
     set used_by = me, used_at = now()
   where c.code = public.normalize_invite_code(redeem_invite.code)
     and c.used_by is null
  returning c.code into taken;
  if taken is null then
    return false;
  end if;

  update auth.users
     set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
                             || '{"invited": true}'::jsonb
   where id = me;
  return true;
end;
$$;

-- Whether the signed-in account has used an invite.
create or replace function public.is_invited()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select (u.raw_app_meta_data ->> 'invited')::boolean
       from auth.users u
      where u.id = (select auth.uid())),
    false);
$$;

revoke all on function public.redeem_invite(text) from public, anon;
grant execute on function public.redeem_invite(text) to authenticated;
revoke all on function public.is_invited() from public, anon;
grant execute on function public.is_invited() to authenticated;
