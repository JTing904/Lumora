-- 一起看 (watch party) rooms are private Realtime channels named
-- 'party:<code>'. Only a signed-in, invited account may listen or send on
-- them; broadcast (sync, chat, reactions) and presence (who is in the room)
-- only. Nothing is stored: Realtime broadcast is not persisted, and the
-- video itself never passes through Supabase.
create policy "party rooms: invited users read"
  on realtime.messages
  for select
  to authenticated
  using (
    realtime.topic() like 'party:%'
    and realtime.messages.extension in ('broadcast', 'presence')
    and (select public.is_invited())
  );

create policy "party rooms: invited users send"
  on realtime.messages
  for insert
  to authenticated
  with check (
    realtime.topic() like 'party:%'
    and realtime.messages.extension in ('broadcast', 'presence')
    and (select public.is_invited())
  );
