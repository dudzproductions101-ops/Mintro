import { supabaseAdmin } from '../config/supabase.js';
import { pushService } from '../notifications/pushService.js';
import { logger } from '../utils/logger.js';

/**
 * Runs at 00:05 UTC daily.
 *
 * 1. Breaks streaks for users who did not earn any XP yesterday and did
 *    not consume a streak freeze.
 * 2. Sends a daily reminder push to users who have not yet earned XP today
 *    (run separately at evening hours — see weeklyLeagueRotation for cron
 *    schedule wiring).
 */
export async function runDailyReset(): Promise<void> {
  logger.info('Running daily reset job');

  const yesterday = new Date();
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const yesterdayStr = yesterday.toISOString().slice(0, 10);

  // Find users whose last_active_date is older than yesterday (i.e. they
  // had no activity yesterday) and still have a streak > 0.
  const { data: atRiskUsers, error } = await supabaseAdmin
    .from('profiles')
    .select('id, current_streak, streak_freeze_count, last_active_date')
    .gt('current_streak', 0)
    .lt('last_active_date', yesterdayStr);

  if (error) {
    logger.error({ err: error }, 'Failed to query at-risk streaks');
    return;
  }

  for (const user of atRiskUsers ?? []) {
    if (user.streak_freeze_count > 0) {
      // Consume a freeze: streak preserved, last_active_date bumped to
      // yesterday so the streak doesn't break again tomorrow if they're
      // still inactive (freeze covers exactly one missed day).
      await supabaseAdmin
        .from('profiles')
        .update({
          streak_freeze_count: user.streak_freeze_count - 1,
          last_active_date: yesterdayStr,
        })
        .eq('id', user.id);

      logger.info({ userId: user.id }, 'Streak freeze consumed');
    } else {
      await supabaseAdmin.from('profiles').update({ current_streak: 0 }).eq('id', user.id);

      await pushService.sendToUser({
        userId: user.id,
        type: 'streak_reminder',
        title: 'Your streak ended 💔',
        body: `Your ${user.current_streak}-day streak was reset. Start a new one today!`,
      });
    }
  }

  logger.info({ count: atRiskUsers?.length ?? 0 }, 'Daily reset job complete');
}

/**
 * Runs at 19:00 UTC daily. Reminds users who haven't met their daily XP
 * goal yet today.
 */
export async function runDailyReminder(): Promise<void> {
  logger.info('Running daily reminder job');

  const today = new Date().toISOString().slice(0, 10);

  const { data: profiles, error } = await supabaseAdmin
    .from('profiles')
    .select('id, daily_xp_goal');

  if (error) {
    logger.error({ err: error }, 'Failed to load profiles for daily reminder');
    return;
  }

  const { data: completedToday, error: logError } = await supabaseAdmin
    .from('daily_xp_log')
    .select('user_id, goal_met')
    .eq('log_date', today);

  if (logError) {
    logger.error({ err: logError }, 'Failed to load daily xp log');
    return;
  }

  const goalMetUserIds = new Set(
    (completedToday ?? []).filter((row) => row.goal_met).map((row) => row.user_id),
  );

  const toRemind = (profiles ?? [])
    .filter((p) => !goalMetUserIds.has(p.id))
    .map((p) => p.id);

  await pushService.sendToUsers(toRemind, {
    type: 'daily_reminder',
    title: "Don't break your streak! 🔥",
    body: "You haven't hit your daily XP goal yet — a quick lesson takes just 2 minutes.",
  });

  logger.info({ count: toRemind.length }, 'Daily reminder job complete');
}
