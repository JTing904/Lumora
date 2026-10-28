-- Profile photos. One public bucket, each account writing only inside its
-- own folder (<user id>/avatar.jpg); the app shrinks photos to 256 px JPEG
-- before uploading, and the bucket refuses anything else or anything big.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 524288, array['image/jpeg'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars: own folder select" on storage.objects;
drop policy if exists "avatars: own folder insert" on storage.objects;
drop policy if exists "avatars: own folder update" on storage.objects;
drop policy if exists "avatars: own folder delete" on storage.objects;

-- Replacing a photo (upsert) reads the old object first.
create policy "avatars: own folder select" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "avatars: own folder insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.is_invited())
  );

create policy "avatars: own folder update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.is_invited())
  );

create policy "avatars: own folder delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- One file per account: <user id>/avatar.jpg, nothing else.
drop policy if exists "avatars: own folder insert" on storage.objects;
drop policy if exists "avatars: own folder update" on storage.objects;

create policy "avatars: own folder insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and name = (select auth.uid())::text || '/avatar.jpg'
    and (select public.is_invited())
  );

create policy "avatars: own folder update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and name = (select auth.uid())::text || '/avatar.jpg'
    and (select public.is_invited())
  );
