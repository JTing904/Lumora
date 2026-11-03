-- No account without an invite code, GitHub and the rest included.
--
-- A GitHub, Discord, Google or Facebook sign-in cannot carry a code to the
-- sign-up trigger, so under 注册 the app checks the code first
-- (invite_code_valid), keeps it while the browser is open, and spends it
-- (redeem_invite) the moment the account comes back. What can still appear
-- is an account made through 登录 by someone with no code, or one whose
-- sign-in was abandoned halfway:
-- 1. discard_uninvited_self lets the app remove the caller's own account,
--    only while it has no invite, right after such a sign-in.
-- 2. Each new sign-up sweeps accounts that still have no invite a day after
--    they were made. This project has no pg_cron to do it on a timer.

create or replace function public.discard_uninvited_self()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
begin
  if me is null or public.is_invited() then
    return false;
  end if;
  delete from auth.users u
   where u.id = me
     and coalesce(u.raw_app_meta_data ->> 'role', '') <> 'admin';
  return found;
end;
$$;

revoke all on function public.discard_uninvited_self() from public, anon;
grant execute on function public.discard_uninvited_self() to authenticated;

create or replace function public.purge_uninvited_accounts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  removed integer;
begin
  delete from auth.users u
   where u.created_at < now() - interval '1 day'
     and not coalesce((u.raw_app_meta_data ->> 'invited')::boolean, false)
     and coalesce(u.raw_app_meta_data ->> 'role', '') <> 'admin'
     and not exists (
       select 1 from public.invite_codes c where c.used_by = u.id);
  get diagnostics removed = row_count;
  return removed;
end;
$$;

revoke all on function public.purge_uninvited_accounts()
  from public, anon, authenticated;

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

  -- Leftovers from sign-ins that never got a code. A failed sweep must not
  -- stop this sign-up.
  begin
    perform public.purge_uninvited_accounts();
  exception when others then
    null;
  end;
  return new;
end;
$$;
