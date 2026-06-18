#!/usr/bin/env node
/**
 * scripts/seed_demo_user.mjs
 *
 * Creates a fully-populated demo account so you can log in immediately
 * and see the app with real data rather than empty states.
 *
 * Usage:
 *   SUPABASE_URL=https://xxx.supabase.co \
 *   SUPABASE_SERVICE_ROLE_KEY=eyJ... \
 *   node scripts/seed_demo_user.mjs
 *
 * Safe to re-run — if the demo user already exists the Auth create call
 * returns a 422, which this script ignores, then upserts all the data.
 *
 * Demo credentials: demo@mintro.app / Mintro2024!
 */

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('❌  Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before running.');
  process.exit(1);
}

const DEMO_EMAIL = 'demo@mintro.app';
const DEMO_PASSWORD = 'Mintro2024!';

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
  'apikey': SERVICE_ROLE_KEY,
};

async function req(method, path, body) {
  const res = await fetch(`${SUPABASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, data: json };
}

// ── 1. Create Auth user ──────────────────────────────────────────────────────
console.log('Creating demo auth user...');
const { status: authStatus, data: authData } = await req('POST', '/auth/v1/admin/users', {
  email: DEMO_EMAIL,
  password: DEMO_PASSWORD,
  email_confirm: true,
  user_metadata: {
    username: 'alexrivera',
    display_name: 'Alex Rivera',
  },
});

let userId;
if (authStatus === 422 || authStatus === 409) {
  console.log('  → user already exists, fetching existing id...');
  const { data: listData } = await req('GET', '/auth/v1/admin/users?page=1&per_page=50');
  const existing = listData.users?.find((u) => u.email === DEMO_EMAIL);
  if (!existing) {
    console.error('❌  Could not find existing demo user. Delete and re-run.');
    process.exit(1);
  }
  userId = existing.id;
} else if (authStatus >= 400) {
  console.error('❌  Failed to create user:', authData);
  process.exit(1);
} else {
  userId = authData.id;
  console.log(`  → created user ${userId}`);
}

// ── 2. Update profile ─────────────────────────────────────────────────────────
console.log('Seeding profile...');
await req('PATCH', `/rest/v1/profiles?id=eq.${userId}`, {
  username: 'alexrivera',
  display_name: 'Alex Rivera',
  total_xp: 9340,
  level: 12,
  coins: 2450,
  current_streak: 12,
  longest_streak: 34,
  last_active_date: new Date().toISOString().slice(0, 10),
  streak_freeze_count: 1,
  league: 'emerald',
  daily_xp_goal: 100,
  currency: 'USD',
});
console.log('  → profile updated');

// ── 3. Seed daily_xp_log for this week ───────────────────────────────────────
console.log('Seeding daily XP log...');
const today = new Date();
const xpRows = [];
for (let i = 6; i >= 0; i--) {
  const d = new Date(today);
  d.setUTCDate(today.getUTCDate() - i);
  const dateStr = d.toISOString().slice(0, 10);
  const dayOfWeek = d.getUTCDay();
  const earnedToday = dayOfWeek === 0 || dayOfWeek === 6 ? 0 : 85 + Math.floor(Math.random() * 60);
  const goal = 100;
  xpRows.push({
    user_id: userId,
    log_date: dateStr,
    xp_earned: earnedToday,
    goal_met: earnedToday >= goal,
  });
}
await req('POST', `/rest/v1/daily_xp_log?on_conflict=user_id,log_date`, xpRows);
console.log(`  → ${xpRows.length} daily XP rows seeded`);

// ── 4. Mark completed lessons ─────────────────────────────────────────────────
console.log('Fetching lessons to mark complete...');
const { data: lessons } = await req('GET', '/rest/v1/lessons?select=id,xp_reward,coin_reward&limit=8');
if (lessons?.length) {
  const completions = lessons.slice(0, 8).map((l) => ({
    user_id: userId,
    lesson_id: l.id,
    completed_at: new Date(Date.now() - Math.random() * 14 * 86400000).toISOString(),
    score: 80 + Math.floor(Math.random() * 20),
    xp_earned: l.xp_reward,
    coins_earned: l.coin_reward,
    attempts: 1,
  }));
  await req('POST', `/rest/v1/user_lessons?on_conflict=user_id,lesson_id`, completions);
  console.log(`  → ${completions.length} lessons marked complete`);
} else {
  console.log('  → no lessons found (run seed.sql first)');
}

// ── 5. Seed savings goals ─────────────────────────────────────────────────────
console.log('Seeding savings goals...');
const { data: existingGoals } = await req('GET', `/rest/v1/goals?user_id=eq.${userId}&select=id&limit=1`);
if (!existingGoals?.length) {
  const { data: goalData } = await req('POST', `/rest/v1/goals`, {
    user_id: userId,
    name: 'Emergency Fund',
    icon: 'shield',
    target_amount: 5000,
    current_amount: 3400,
    currency: 'USD',
    deadline: null,
    status: 'active',
  });
  // If the goal was created (REST POST returns array), seed its milestones
  const goalId = Array.isArray(goalData) ? goalData[0]?.id : goalData?.id;
  if (goalId) {
    await req('POST', `/rest/v1/goal_milestones`, [
      { goal_id: goalId, percentage: 25, reached: true,  reached_at: new Date(Date.now() - 30 * 86400000).toISOString() },
      { goal_id: goalId, percentage: 50, reached: true,  reached_at: new Date(Date.now() - 15 * 86400000).toISOString() },
      { goal_id: goalId, percentage: 75, reached: false, reached_at: null },
      { goal_id: goalId, percentage: 100, reached: false, reached_at: null },
    ]);
    console.log('  → Emergency Fund goal seeded with milestones');
  }

  await req('POST', `/rest/v1/goals`, {
    user_id: userId,
    name: 'Vacation to Japan',
    icon: 'plane',
    target_amount: 3000,
    current_amount: 750,
    currency: 'USD',
    deadline: new Date(Date.now() + 180 * 86400000).toISOString().slice(0, 10),
    status: 'active',
  });
  console.log('  → Vacation goal seeded');
} else {
  console.log('  → goals already exist, skipping');
}

// ── 6. Seed league_members row for this week ─────────────────────────────────
console.log('Seeding league membership...');
const now2 = new Date();
const dayOfWeek2 = now2.getUTCDay();
const diffToMonday = (dayOfWeek2 + 6) % 7;
const monday = new Date(now2);
monday.setUTCDate(now2.getUTCDate() - diffToMonday);
const weekStart = monday.toISOString().slice(0, 10);

await req('POST', `/rest/v1/league_members?on_conflict=user_id,week_start`, {
  user_id: userId,
  league_tier: 'emerald',
  week_start: weekStart,
  weekly_xp: 4820,
  rank_in_league: 4,
  promoted: false,
  demoted: false,
});
console.log(`  → league_members row for week ${weekStart}`);

// ── 7. Seed an active quest ───────────────────────────────────────────────────
console.log('Seeding active quest progress...');
const { data: questTemplates } = await req('GET', '/rest/v1/quests?select=id,period,target_value&limit=3');
if (questTemplates?.length) {
  const today2 = new Date().toISOString().slice(0, 10);
  for (const qt of questTemplates.slice(0, 2)) {
    const periodEnd = qt.period === 'daily' ? today2 : weekStart;
    await req('POST', `/rest/v1/user_quests?on_conflict=user_id,quest_id,period_start`, {
      user_id: userId,
      quest_id: qt.id,
      period_start: qt.period === 'daily' ? today2 : weekStart,
      period_end: periodEnd,
      current_value: Math.floor(qt.target_value * 0.66),
      completed: false,
      claimed: false,
    });
  }
  console.log('  → active quests seeded');
}

// ── 8. Seed a couple of earned achievements ───────────────────────────────────
console.log('Seeding achievements...');
const { data: achievementList } = await req('GET', '/rest/v1/achievements?select=id&order=sort_order&limit=3');
if (achievementList?.length) {
  const earnedRows = achievementList.slice(0, 3).map((a) => ({
    user_id: userId,
    achievement_id: a.id,
    earned_at: new Date(Date.now() - Math.random() * 20 * 86400000).toISOString(),
  }));
  await req('POST', `/rest/v1/user_achievements?on_conflict=user_id,achievement_id`, earnedRows);
  console.log(`  → ${earnedRows.length} achievements awarded`);
}

console.log('\n✅  Demo account seeded successfully.');
console.log(`   Email:    ${DEMO_EMAIL}`);
console.log(`   Password: ${DEMO_PASSWORD}`);
console.log('   Profile:  Alex Rivera · Emerald League · Level 12 · 12-day streak');
