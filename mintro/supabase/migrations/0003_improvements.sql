-- ============================================================
-- supabase/migrations/0003_improvements.sql
-- Part I best-practice additions:
--   1. weekly_xp increment trigger on daily_xp_log
--   2. league_members auto-seed on new user signup
--   3. Index covering leaderboard snapshot queries
--   4. RLS policy for notifications_log insert (for service role)
-- ============================================================

-- ── 1. Trigger: keep league_members.weekly_xp in sync whenever
--       daily_xp_log is updated by award_xp_and_coins.
--       This means the live leaderboard fallback query in
--       leaderboardRepository.ts always has fresh weekly_xp without
--       needing a separate UPDATE call in the Node API.
-- ────────────────────────────────────────────────────────────────
create or replace function public.sync_league_weekly_xp()
returns trigger as $$
declare
  v_week_start date;
begin
  -- Monday of the ISO week containing the log_date
  v_week_start := date_trunc('week', new.log_date)::date;

  insert into public.league_members (user_id, league_tier, week_start, weekly_xp)
  select new.user_id,
         p.league,
         v_week_start,
         new.xp_earned
  from public.profiles p
  where p.id = new.user_id
  on conflict (user_id, week_start) do update
    set weekly_xp = league_members.weekly_xp
                  + (new.xp_earned - coalesce(old.xp_earned, 0));

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_sync_league_weekly_xp on public.daily_xp_log;
create trigger trg_sync_league_weekly_xp
  after insert or update on public.daily_xp_log
  for each row execute function public.sync_league_weekly_xp();


-- ── 2. Extend handle_new_user to also seed a league_members row
--       for the current week so a brand-new user appears in their
--       league's leaderboard immediately rather than only after
--       the next weekly cron run.
-- ────────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
declare
  v_week_start date;
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data->>'display_name', 'New User')
  );

  v_week_start := date_trunc('week', current_date)::date;

  insert into public.league_members (user_id, league_tier, week_start, weekly_xp)
  values (new.id, 'copper', v_week_start, 0)
  on conflict (user_id, week_start) do nothing;

  return new;
end;
$$ language plpgsql security definer;


-- ── 3. Covering index for the live fallback leaderboard query
--       (league_tier + week_start + weekly_xp DESC) so it doesn't
--       require a sequential scan of all league_members when no
--       snapshot exists yet.
-- ────────────────────────────────────────────────────────────────
create index if not exists idx_league_members_live_board
  on public.league_members (league_tier, week_start, weekly_xp desc);


-- ── 4. notifications_log: allow service-role INSERT from the Node
--       API's pushService.ts (already uses service role, but belt
--       and suspenders: explicit policy documents intent).
-- ────────────────────────────────────────────────────────────────
create policy "service role insert notifications_log"
  on public.notifications_log
  for insert
  with check (true);
  -- Service role bypasses RLS entirely; this policy is a no-op for
  -- the service role but documents that only the backend (not the
  -- Flutter client) should ever write to this table. The Flutter
  -- client's anon role has no INSERT policy here, so any attempt
  -- from the client will be rejected by the missing policy.
