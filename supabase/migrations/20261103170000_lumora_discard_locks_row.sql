-- discard_uninvited_self waits for a redeem in progress.
--
-- redeem_invite locks the caller's auth.users row before it checks and
-- spends a code. discard_uninvited_self checked is_invited() without that
-- lock, so a removal and a redeem for the same new account could interleave:
-- the check saw no invite, the redeem committed, and the delete then removed
-- an account that had just spent its code. Taking the same row lock first
-- puts the two in order; whichever comes second sees the other's result.

create or replace function public.discard_uninvited_self()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
begin
  if me is null then
    return false;
  end if;
  perform 1 from auth.users where id = me for update;
  if public.is_invited() then
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
