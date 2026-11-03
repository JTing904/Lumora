-- 一起看 rooms get members. NOT APPLIED: apply only together with the client
-- change described at the end, or every room stops working.
--
-- Until now any invited account could listen and send on any 'party:%'
-- topic: knowing (or guessing) a room's code was the only gate, and nothing
-- on the server knew who a room's host was. This adds a row per room naming
-- its host, and a row per member, and lets only those accounts use the
-- room's channel.
--
-- What it cannot do: tell one message from another. Realtime checks these
-- policies once, when a client joins the channel (it inserts a test message
-- and rolls it back), and caches the answer for the connection. So "only the
-- host may send `end` or `state`" cannot be a policy; the client keeps
-- enforcing that (PartyAuthority in lib/services/party/party_rules.dart).
-- What the server does give is a host_id a guest can trust, instead of the
-- host's own word in its messages.

create table if not exists public.party_rooms (
  code text primary key check (code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  host_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.party_members (
  code text not null references public.party_rooms (code) on delete cascade,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (code, user_id)
);

create index if not exists party_members_user_idx
  on public.party_members (user_id);

alter table public.party_rooms enable row level security;
alter table public.party_members enable row level security;

-- A room lasts a day at most: an old row no longer opens its channel, so a
-- code that leaked last week is worth nothing. Old rows can be deleted at
-- leisure; nothing reads them.
create or replace function public.is_party_member(p_topic text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.party_rooms r
     where p_topic = 'party:' || r.code
       and r.code = substring(p_topic from 7)
       and r.created_at > now() - interval '1 day'
       and (
         r.host_id = (select auth.uid())
         or exists (
           select 1
             from public.party_members m
            where m.code = r.code
              and m.user_id = (select auth.uid())
         )
       )
  );
$$;

revoke all on function public.is_party_member(text) from public, anon;
grant execute on function public.is_party_member(text) to authenticated;

-- Rooms: an invited account opens one as its own host, its members can see
-- who the host is, and the host closes it.
create policy "party rooms: open as host"
  on public.party_rooms
  for insert
  to authenticated
  with check (
    host_id = (select auth.uid())
    and (select public.is_invited())
  );

create policy "party rooms: members see the room"
  on public.party_rooms
  for select
  to authenticated
  using ((select public.is_party_member('party:' || code)));

create policy "party rooms: host closes"
  on public.party_rooms
  for delete
  to authenticated
  using (host_id = (select auth.uid()));

-- Members: an invited account joins a room by its code, as itself. Joining
-- still only needs the code, as before; what changes is that the channel
-- now needs the join. A member sees and leaves its own membership, and the
-- host sees and removes anyone's.
create policy "party members: join as self"
  on public.party_members
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and (select public.is_invited())
  );

create policy "party members: see own or as host"
  on public.party_members
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.party_rooms r
       where r.code = party_members.code
         and r.host_id = (select auth.uid())
    )
  );

create policy "party members: leave or be removed by the host"
  on public.party_members
  for delete
  to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.party_rooms r
       where r.code = party_members.code
         and r.host_id = (select auth.uid())
    )
  );

-- The channel: only the room's host and members, instead of every invited
-- account.
drop policy if exists "party rooms: invited users read" on realtime.messages;
drop policy if exists "party rooms: invited users send" on realtime.messages;

create policy "party rooms: members read"
  on realtime.messages
  for select
  to authenticated
  using (
    realtime.topic() like 'party:%'
    and realtime.messages.extension in ('broadcast', 'presence')
    and (select public.is_invited())
    and (select public.is_party_member(realtime.topic()))
  );

create policy "party rooms: members send"
  on realtime.messages
  for insert
  to authenticated
  with check (
    realtime.topic() like 'party:%'
    and realtime.messages.extension in ('broadcast', 'presence')
    and (select public.is_invited())
    and (select public.is_party_member(realtime.topic()))
  );

-- The client change this needs, in WatchPartyService (not made yet):
--   * create(): insert into party_rooms (code) before subscribing; retry
--     with a new code on a primary-key conflict.
--   * join(): insert into party_members (code) before subscribing (ignore a
--     duplicate); a foreign-key error means no such room.
--   * leave() as host: delete the party_rooms row (members go with it);
--     as guest: delete its own party_members row.
--   * optional: a guest reads party_rooms.host_id and accepts a `state`
--     only when its hostUid matches.
-- A room's channel is checked when it is joined and again when the JWT is
-- refreshed, so a removed member is shut out at its next refresh at most.
