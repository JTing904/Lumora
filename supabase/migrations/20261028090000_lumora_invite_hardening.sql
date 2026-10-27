-- Invite state that survives sign-up, and the invite gate on the server.
--
-- 1. An account counts as invited when it spent a code (invite_codes.used_by)
--    or carries app_metadata.invited. The sign-up trigger writes the flag
--    into auth.users while Auth is still creating the row, and Auth writes
--    its own copy of app_metadata afterwards; the spent code is the record
--    that cannot be overwritten.
-- 2. redeem_invite locks the caller's row first, so two codes sent at once
--    cannot both be spent on one account.
-- 3. Every per-user table also requires an invited account: an OAuth account
--    that never entered a code holds a valid session but no app data.

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
    false)
  or exists (
    select 1 from public.invite_codes c
     where c.used_by = (select auth.uid()));
$$;

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
  -- One redemption per account at a time.
  perform 1 from auth.users where id = me for update;
  if public.is_invited() then
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

revoke all on function public.redeem_invite(text) from public, anon;
grant execute on function public.redeem_invite(text) to authenticated;
revoke all on function public.is_invited() from public, anon;
grant execute on function public.is_invited() to authenticated;

-- The server-side invite gate, alongside each table's own-rows policy.
do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'scene_clips', 'watch_history', 'playback_progress',
    'watchlist', 'user_settings'
  ] loop
    if to_regclass('public.' || t) is not null then
      execute format('drop policy if exists "invited only" on public.%I', t);
      execute format(
        'create policy "invited only" on public.%I as restrictive '
        'for all to authenticated '
        'using ((select public.is_invited())) '
        'with check ((select public.is_invited()))', t);
    end if;
  end loop;
end;
$$;
