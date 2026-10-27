-- Each account's library, so it follows the account to another device:
-- one row per account per document (continue_watching, my_list,
-- watched_episodes, taste), the document as JSON, newest copy wins on the
-- client by client_updated_at.

create table if not exists public.user_documents (
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  doc text not null
    check (doc in ('continue_watching', 'my_list', 'watched_episodes', 'taste')),
  data jsonb not null default '[]'::jsonb,
  client_updated_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, doc),
  -- A library document stays a library document, not a file store.
  constraint user_documents_size check (pg_column_size(data) < 2000000)
);

alter table public.user_documents enable row level security;

create policy "own documents" on public.user_documents
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Same gate as every other per-user table: invited accounts only.
create policy "invited only" on public.user_documents as restrictive
  for all to authenticated
  using ((select public.is_invited()))
  with check ((select public.is_invited()));

revoke all on public.user_documents from anon;
grant select, insert, update, delete on public.user_documents to authenticated;

create or replace function public.touch_user_documents()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger user_documents_touch
  before update on public.user_documents
  for each row execute function public.touch_user_documents();
