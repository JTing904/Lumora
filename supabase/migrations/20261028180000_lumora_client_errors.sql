-- Crash reports from release builds: one row per error a signed-in, invited
-- account's app ran into. Write-only for the app; only the dashboard (the
-- service role) reads them. The app scrubs secrets, URLs and paths before
-- sending, and the database caps both the size of a row and how many rows
-- one account can add in a day.

create table if not exists public.client_errors (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  app_version text,
  platform text,
  kind text,
  message text,
  stack text
);

create index if not exists client_errors_user_created_idx
  on public.client_errors (user_id, created_at);

alter table public.client_errors enable row level security;

-- Insert only: no select, update or delete policy, so the app can add its
-- own reports and never read anyone's (its own included).
drop policy if exists "insert own reports" on public.client_errors;
create policy "insert own reports" on public.client_errors
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (select public.is_invited())
    and char_length(message) <= 2000
    and char_length(coalesce(stack, '')) <= 8000
    and char_length(coalesce(app_version, '')) <= 40
    and char_length(coalesce(platform, '')) <= 40
    and char_length(coalesce(kind, '')) <= 20
  );

revoke all on public.client_errors from anon;
revoke all on public.client_errors from authenticated;
grant insert on public.client_errors to authenticated;

-- At most 50 reports per account per 24 hours. Security definer so it can
-- count rows the caller cannot select; the timestamp is the server's, so a
-- client cannot backdate rows out of the window; the per-account lock keeps
-- two reports sent at once from both slipping past the count.
create or replace function public.client_errors_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.created_at := now();
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('client_errors:' || new.user_id::text, 0));
  if (select count(*)
        from public.client_errors e
       where e.user_id = new.user_id
         and e.created_at > now() - interval '24 hours') >= 50 then
    raise exception 'client_errors: daily report limit reached'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.client_errors_rate_limit() from public, anon, authenticated;

drop trigger if exists client_errors_rate_limit on public.client_errors;
create trigger client_errors_rate_limit
  before insert on public.client_errors
  for each row execute function public.client_errors_rate_limit();
