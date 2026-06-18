import { supabaseAdmin } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';

export interface Profile {
  id: string;
  username: string;
  display_name: string;
  avatar_url: string | null;
  currency: string;
  total_xp: number;
  level: number;
  coins: number;
  current_streak: number;
  longest_streak: number;
  last_active_date: string | null;
  streak_freeze_count: number;
  league: string;
  daily_xp_goal: number;
  fcm_token: string | null;
  notification_prefs: Record<string, boolean>;
}

export const profileRepository = {
  async getById(userId: string): Promise<Profile> {
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error || !data) {
      throw Errors.notFound('Profile not found');
    }

    return data as Profile;
  },

  async getDailyXpProgress(userId: string, date: string) {
    const { data, error } = await supabaseAdmin
      .from('daily_xp_log')
      .select('xp_earned, goal_met')
      .eq('user_id', userId)
      .eq('log_date', date)
      .maybeSingle();

    if (error) {
      throw Errors.internal('Failed to load daily XP progress');
    }

    return data ?? { xp_earned: 0, goal_met: false };
  },
};
