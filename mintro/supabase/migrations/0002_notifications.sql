-- ============================================================
-- MINTRO — Notifications addendum
-- File: supabase/migrations/0002_notifications.sql
-- ============================================================

alter table public.profiles
  add column fcm_token text,
  add column notification_prefs jsonb not null default '{
    "daily_reminder": true,
    "streak_reminder": true,
    "goal_reminder": true,
    "achievement_alerts": true,
    "league_promotion": true
  }'::jsonb;

create table public.notifications_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  sent_at timestamptz not null default now(),
  read_at timestamptz
);

create index idx_notifications_log_user on public.notifications_log(user_id, sent_at desc);

alter table public.notifications_log enable row level security;

create policy "owner read notifications_log" on public.notifications_log
  for select using (auth.uid() = user_id);

create policy "owner update notifications_log" on public.notifications_log
  for update using (auth.uid() = user_id);
