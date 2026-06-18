import { supabaseAdmin } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';
import { logger } from '../utils/logger.js';

export interface XpAwardResult {
  newTotalXp: number;
  newLevel: number;
  newCoins: number;
  leveledUp: boolean;
}

export interface StreakResult {
  currentStreak: number;
  longestStreak: number;
  streakExtended: boolean;
}

/**
 * Thin wrapper around the Postgres functions defined in
 * supabase/migrations/0001_init.sql. These run with SECURITY DEFINER so
 * that XP/coins/streak fields — which are write-protected from the client
 * by RLS — can only be mutated through this audited path.
 */
export const gamificationService = {
  async awardXpAndCoins(userId: string, xp: number, coins: number): Promise<XpAwardResult> {
    if (xp < 0 || coins < 0) {
      throw Errors.badRequest('XP and coin rewards must be non-negative');
    }

    const { data, error } = await supabaseAdmin
      .rpc('award_xp_and_coins', {
        p_user_id: userId,
        p_xp: xp,
        p_coins: coins,
      })
      .single();

    if (error || !data) {
      logger.error({ err: error, userId, xp, coins }, 'award_xp_and_coins RPC failed');
      throw Errors.internal('Failed to award XP and coins');
    }

    const row = data as {
      new_total_xp: number;
      new_level: number;
      new_coins: number;
      leveled_up: boolean;
    };

    return {
      newTotalXp: row.new_total_xp,
      newLevel: row.new_level,
      newCoins: row.new_coins,
      leveledUp: row.leveled_up,
    };
  },

  async updateStreak(userId: string): Promise<StreakResult> {
    const { data, error } = await supabaseAdmin
      .rpc('update_streak', { p_user_id: userId })
      .single();

    if (error || !data) {
      logger.error({ err: error, userId }, 'update_streak RPC failed');
      throw Errors.internal('Failed to update streak');
    }

    const row = data as { current_streak: number; longest_streak: number };

    return {
      currentStreak: row.current_streak,
      longestStreak: row.longest_streak,
      streakExtended: true,
    };
  },

  /**
   * Returns true if this is the user's first lesson completion of the day
   * (i.e. whether updateStreak should be called). Determined by checking
   * whether a daily_xp_log row already exists for today with xp_earned > 0
   * BEFORE this award — callers should check this prior to awarding XP.
   */
  async isFirstActivityToday(userId: string): Promise<boolean> {
    const today = new Date().toISOString().slice(0, 10);

    const { data, error } = await supabaseAdmin
      .from('daily_xp_log')
      .select('xp_earned')
      .eq('user_id', userId)
      .eq('log_date', today)
      .maybeSingle();

    if (error) {
      throw Errors.internal('Failed to check daily activity');
    }

    return !data || data.xp_earned === 0;
  },
};
