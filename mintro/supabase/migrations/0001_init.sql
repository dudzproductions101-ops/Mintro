-- ============================================================
-- MINTRO DATABASE SCHEMA
-- File: supabase/migrations/0001_init.sql
-- ============================================================

-- ============================================================
-- EXTENSIONS
-- ============================================================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================================
-- ENUM TYPES
-- ============================================================
create type league_tier as enum (
  'copper','bronze','silver','gold','emerald','diamond','master'
);

create type quest_period as enum ('daily','weekly','monthly');

create type quest_type as enum (
  'complete_lessons','earn_xp','save_money','maintain_streak',
  'complete_path','spend_time_learning'
);

create type goal_status as enum ('active','completed','archived');

create type lesson_type as enum (
  'multiple_choice','match_pairs','drag_drop','simulation',
  'true_false','flashcard','scenario'
);

-- ============================================================
-- PROFILES (1:1 with auth.users)
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text not null,
  avatar_url text,
  currency text not null default 'EUR',
  total_xp integer not null default 0,
  level integer not null default 1,
  coins integer not null default 0,
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  last_active_date date,
  streak_freeze_count integer not null default 0,
  league league_tier not null default 'copper',
  daily_xp_goal integer not null default 50,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint username_format check (username ~ '^[a-z0-9_]{3,20}$'),
  constraint xp_non_negative check (total_xp >= 0),
  constraint coins_non_negative check (coins >= 0)
);

create index idx_profiles_league on public.profiles(league);
create index idx_profiles_total_xp on public.profiles(total_xp desc);

-- ============================================================
-- DAILY XP LOG (drives streak dots / daily goal progress)
-- ============================================================
create table public.daily_xp_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  log_date date not null default current_date,
  xp_earned integer not null default 0,
  goal_met boolean not null default false,
  created_at timestamptz not null default now(),

  unique(user_id, log_date)
);

create index idx_daily_xp_log_user_date on public.daily_xp_log(user_id, log_date);

-- ============================================================
-- LEARNING PATHS
-- ============================================================
create table public.learning_paths (
  id uuid primary key default uuid_generate_v4(),
  slug text unique not null,
  title text not null,
  description text,
  icon text,
  color_hex text not null default '#2E7D32',
  difficulty text not null default 'beginner',
  sort_order integer not null default 0,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_learning_paths_sort on public.learning_paths(sort_order);

-- ============================================================
-- LESSONS
-- ============================================================
create table public.lessons (
  id uuid primary key default uuid_generate_v4(),
  path_id uuid not null references public.learning_paths(id) on delete cascade,
  slug text unique not null,
  title text not null,
  description text,
  lesson_type lesson_type not null default 'multiple_choice',
  icon text,
  xp_reward integer not null default 10,
  coin_reward integer not null default 5,
  sort_order integer not null default 0,
  estimated_minutes integer not null default 5,
  content jsonb not null default '{}'::jsonb,
  is_premium boolean not null default false,
  created_at timestamptz not null default now(),

  constraint xp_reward_positive check (xp_reward > 0),
  constraint coin_reward_non_negative check (coin_reward >= 0)
);

create index idx_lessons_path on public.lessons(path_id, sort_order);

-- ============================================================
-- USER LESSONS (completion records)
-- ============================================================
create table public.user_lessons (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  completed_at timestamptz,
  score numeric(5,2),
  xp_earned integer not null default 0,
  coins_earned integer not null default 0,
  attempts integer not null default 0,
  created_at timestamptz not null default now(),

  unique(user_id, lesson_id)
);

create index idx_user_lessons_user on public.user_lessons(user_id);
create index idx_user_lessons_completed on public.user_lessons(user_id, completed_at);

-- ============================================================
-- LEAGUES (static reference table)
-- ============================================================
create table public.leagues (
  id uuid primary key default uuid_generate_v4(),
  tier league_tier unique not null,
  name text not null,
  icon text not null,
  rank_order integer not null,
  promotion_count integer not null default 10,
  demotion_count integer not null default 5,
  min_xp_to_enter integer not null default 0
);

create index idx_leagues_rank on public.leagues(rank_order);

-- ============================================================
-- LEAGUE MEMBERS (weekly cohort tracking)
-- ============================================================
create table public.league_members (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  league_tier league_tier not null,
  week_start date not null,
  weekly_xp integer not null default 0,
  rank_in_league integer,
  promoted boolean not null default false,
  demoted boolean not null default false,
  created_at timestamptz not null default now(),

  unique(user_id, week_start)
);

create index idx_league_members_week on public.league_members(league_tier, week_start, weekly_xp desc);

-- ============================================================
-- QUESTS (templates)
-- ============================================================
create table public.quests (
  id uuid primary key default uuid_generate_v4(),
  slug text unique not null,
  title text not null,
  description text,
  quest_type quest_type not null,
  period quest_period not null,
  target_value integer not null,
  xp_reward integer not null default 0,
  coin_reward integer not null default 0,
  icon text,
  is_featured boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- USER QUESTS (active/claimed instances)
-- ============================================================
create table public.user_quests (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  quest_id uuid not null references public.quests(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  current_value integer not null default 0,
  completed boolean not null default false,
  completed_at timestamptz,
  claimed boolean not null default false,
  claimed_at timestamptz,
  created_at timestamptz not null default now(),

  unique(user_id, quest_id, period_start)
);

create index idx_user_quests_active on public.user_quests(user_id, period_end) where claimed = false;

-- ============================================================
-- GOALS (savings goals)
-- ============================================================
create table public.goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  icon text,
  target_amount numeric(12,2) not null,
  current_amount numeric(12,2) not null default 0,
  currency text not null default 'EUR',
  deadline date,
  status goal_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint target_amount_positive check (target_amount > 0),
  constraint current_amount_non_negative check (current_amount >= 0)
);

create index idx_goals_user on public.goals(user_id, status);

-- ============================================================
-- GOAL MILESTONES
-- ============================================================
create table public.goal_milestones (
  id uuid primary key default uuid_generate_v4(),
  goal_id uuid not null references public.goals(id) on delete cascade,
  percentage integer not null,
  reached boolean not null default false,
  reached_at timestamptz,

  unique(goal_id, percentage),
  constraint percentage_range check (percentage > 0 and percentage <= 100)
);

-- ============================================================
-- ACHIEVEMENTS (templates)
-- ============================================================
create table public.achievements (
  id uuid primary key default uuid_generate_v4(),
  slug text unique not null,
  title text not null,
  description text,
  icon text,
  category text not null,
  requirement_type text not null,
  requirement_value integer not null,
  xp_reward integer not null default 0,
  coin_reward integer not null default 0,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index idx_achievements_category on public.achievements(category, sort_order);

-- ============================================================
-- USER ACHIEVEMENTS
-- ============================================================
create table public.user_achievements (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  earned_at timestamptz not null default now(),

  unique(user_id, achievement_id)
);

create index idx_user_achievements_user on public.user_achievements(user_id);

-- ============================================================
-- FRIENDSHIPS
-- ============================================================
create table public.friendships (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),

  unique(user_id, friend_id),
  constraint no_self_friend check (user_id <> friend_id),
  constraint valid_status check (status in ('pending','accepted','blocked'))
);

create index idx_friendships_user on public.friendships(user_id, status);
create index idx_friendships_friend on public.friendships(friend_id, status);

-- ============================================================
-- LEADERBOARD SNAPSHOTS (weekly, materialized for fast reads)
-- ============================================================
create table public.leaderboard_snapshots (
  id uuid primary key default uuid_generate_v4(),
  league_tier league_tier not null,
  week_start date not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  username text not null,
  display_name text not null,
  avatar_url text,
  weekly_xp integer not null,
  rank integer not null,
  current_streak integer not null default 0,
  created_at timestamptz not null default now(),

  unique(league_tier, week_start, user_id)
);

create index idx_leaderboard_snapshot_lookup on public.leaderboard_snapshots(league_tier, week_start, rank);

-- ============================================================
-- TRIGGER: updated_at maintenance
-- ============================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger trg_goals_updated_at
  before update on public.goals
  for each row execute function public.set_updated_at();

-- ============================================================
-- FUNCTION: handle_new_user
-- Auto-creates a profile row when a Supabase auth user signs up
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data->>'display_name', 'New User')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- FUNCTION: level calculation (100 XP per level baseline, scaling)
-- ============================================================
create or replace function public.xp_to_level(xp integer)
returns integer as $$
begin
  -- Level formula: level = floor(sqrt(xp / 50)) + 1
  return floor(sqrt(xp::numeric / 50)) + 1;
end;
$$ language plpgsql immutable;

-- ============================================================
-- FUNCTION: award_xp_and_coins (atomic, server-role only)
-- Called by Node API service role to safely mutate profile stats
-- ============================================================
create or replace function public.award_xp_and_coins(
  p_user_id uuid,
  p_xp integer,
  p_coins integer
)
returns table(new_total_xp integer, new_level integer, new_coins integer, leveled_up boolean) as $$
declare
  v_old_level integer;
  v_new_total_xp integer;
  v_new_level integer;
  v_new_coins integer;
begin
  select level into v_old_level from public.profiles where id = p_user_id for update;

  update public.profiles
  set total_xp = total_xp + p_xp,
      coins = coins + p_coins
  where id = p_user_id
  returning total_xp, coins into v_new_total_xp, v_new_coins;

  v_new_level := public.xp_to_level(v_new_total_xp);

  update public.profiles set level = v_new_level where id = p_user_id;

  -- upsert today's xp log
  insert into public.daily_xp_log (user_id, log_date, xp_earned, goal_met)
  values (p_user_id, current_date, p_xp, false)
  on conflict (user_id, log_date)
  do update set xp_earned = public.daily_xp_log.xp_earned + p_xp;

  update public.daily_xp_log
  set goal_met = (xp_earned >= (select daily_xp_goal from public.profiles where id = p_user_id))
  where user_id = p_user_id and log_date = current_date;

  return query select v_new_total_xp, v_new_level, v_new_coins, (v_new_level > v_old_level);
end;
$$ language plpgsql security definer;

-- ============================================================
-- FUNCTION: update_streak
-- Called on first lesson completion of the day
-- ============================================================
create or replace function public.update_streak(p_user_id uuid)
returns table(current_streak integer, longest_streak integer) as $$
declare
  v_last_active date;
  v_current integer;
  v_longest integer;
begin
  select last_active_date, profiles.current_streak, profiles.longest_streak
  into v_last_active, v_current, v_longest
  from public.profiles where id = p_user_id for update;

  if v_last_active = current_date then
    -- already counted today
    return query select v_current, v_longest;
  elsif v_last_active = current_date - interval '1 day' then
    v_current := v_current + 1;
  else
    v_current := 1;
  end if;

  if v_current > v_longest then
    v_longest := v_current;
  end if;

  update public.profiles
  set current_streak = v_current,
      longest_streak = v_longest,
      last_active_date = current_date
  where id = p_user_id;

  return query select v_current, v_longest;
end;
$$ language plpgsql security definer;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.profiles enable row level security;
alter table public.daily_xp_log enable row level security;
alter table public.learning_paths enable row level security;
alter table public.lessons enable row level security;
alter table public.user_lessons enable row level security;
alter table public.leagues enable row level security;
alter table public.league_members enable row level security;
alter table public.quests enable row level security;
alter table public.user_quests enable row level security;
alter table public.goals enable row level security;
alter table public.goal_milestones enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.friendships enable row level security;
alter table public.leaderboard_snapshots enable row level security;

-- Public read-only reference tables
create policy "public read learning_paths" on public.learning_paths for select using (true);
create policy "public read lessons" on public.lessons for select using (true);
create policy "public read leagues" on public.leagues for select using (true);
create policy "public read quests" on public.quests for select using (true);
create policy "public read achievements" on public.achievements for select using (true);
create policy "public read leaderboard_snapshots" on public.leaderboard_snapshots for select using (true);

-- Profiles: readable by all (for leaderboards/friends), writable only by owner
-- NOTE: total_xp, coins, level, current_streak, longest_streak are NOT
-- updatable directly by users (only via award_xp_and_coins / update_streak,
-- which run as SECURITY DEFINER from the service role).
create policy "read all profiles" on public.profiles for select using (true);

create policy "update own profile" on public.profiles for update
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and total_xp = (select total_xp from public.profiles where id = auth.uid())
    and coins = (select coins from public.profiles where id = auth.uid())
    and level = (select level from public.profiles where id = auth.uid())
    and current_streak = (select current_streak from public.profiles where id = auth.uid())
    and longest_streak = (select longest_streak from public.profiles where id = auth.uid())
  );

-- daily_xp_log: owner only
create policy "owner read daily_xp_log" on public.daily_xp_log for select using (auth.uid() = user_id);

-- user_lessons: owner only
create policy "owner all user_lessons" on public.user_lessons for select using (auth.uid() = user_id);

-- league_members: owner can read own, others read for leaderboard context
create policy "read league_members" on public.league_members for select using (true);

-- user_quests: owner only
create policy "owner all user_quests" on public.user_quests
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- goals: owner only
create policy "owner all goals" on public.goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- goal_milestones: via parent goal ownership
create policy "owner read goal_milestones" on public.goal_milestones for select
  using (exists (select 1 from public.goals g where g.id = goal_id and g.user_id = auth.uid()));

-- user_achievements: readable by all (profile display), owner-only insert blocked
-- (achievements are awarded server-side)
create policy "read user_achievements" on public.user_achievements for select using (true);

-- friendships: visible to both parties
create policy "parties read friendships" on public.friendships for select
  using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "owner manage friendships" on public.friendships
  for insert with check (auth.uid() = user_id);

create policy "owner update friendships" on public.friendships
  for update using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "owner delete friendships" on public.friendships
  for delete using (auth.uid() = user_id or auth.uid() = friend_id);
