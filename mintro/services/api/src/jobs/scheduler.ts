import cron from 'node-cron';
import { runDailyReset, runDailyReminder } from './dailyReset.js';
import { runWeeklyLeagueRotation } from './weeklyLeagueRotation.js';
import { logger } from '../utils/logger.js';

/**
 * Registers all cron jobs. Call once from server.ts after the Fastify
 * instance is listening. All times are UTC.
 */
export function startScheduledJobs(): void {
  // 00:05 daily — streak break detection
  cron.schedule('5 0 * * *', () => {
    runDailyReset().catch((err) => logger.error({ err }, 'runDailyReset failed'));
  });

  // 19:00 daily — "you haven't hit your goal yet" reminder
  cron.schedule('0 19 * * *', () => {
    runDailyReminder().catch((err) => logger.error({ err }, 'runDailyReminder failed'));
  });

  // Sunday 23:55 — league promotions/demotions + leaderboard snapshot
  cron.schedule('55 23 * * 0', () => {
    runWeeklyLeagueRotation().catch((err) =>
      logger.error({ err }, 'runWeeklyLeagueRotation failed'),
    );
  });

  logger.info('Scheduled jobs registered (daily reset, daily reminder, weekly league rotation)');
}
