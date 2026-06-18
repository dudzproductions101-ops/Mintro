import { supabaseAdmin } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';
import { profileRepository } from './profileRepository.js';
import { getPeriodRange } from './questRepository.js';

export interface LeaderboardEntry {
  rank: number;
  user_id: string;
  username: string;
  display_name: string;
  avatar_url: string | null;
  weekly_xp: number;
  current_streak: number;
  is_current_user: boolean;
}

export interface LeaderboardResult {
  league: string;
  weekStart: string;
  entries: LeaderboardEntry[];
  currentUserRank: number | null;
  totalInLeague: number;
}

export const leaderboardRepository = {
  /**
   * Returns the most recently computed leaderboard for the league the
   * requesting user currently belongs to. Falls back to a live query
   * against `league_members` if no snapshot has been generated yet
   * (e.g. mid-week before the first cron run).
   */
  async getForUser(userId: string): Promise<LeaderboardResult> {
    const profile = await profileRepository.getById(userId);
    const { start } = getPeriodRange('weekly');

    const { data: snapshot, error: snapshotError } = await supabaseAdmin
      .from('leaderboard_snapshots')
      .select('*')
      .eq('league_tier', profile.league)
      .eq('week_start', start)
      .order('rank', { ascending: true });

    if (snapshotError) {
      throw Errors.internal('Failed to load leaderboard snapshot');
    }

    if (snapshot && snapshot.length > 0) {
      const entries: LeaderboardEntry[] = snapshot.map((row) => ({
        rank: row.rank,
        user_id: row.user_id,
        username: row.username,
        display_name: row.display_name,
        avatar_url: row.avatar_url,
        weekly_xp: row.weekly_xp,
        current_streak: row.current_streak,
        is_current_user: row.user_id === userId,
      }));

      const currentUserEntry = entries.find((e) => e.is_current_user);

      return {
        league: profile.league,
        weekStart: start,
        entries,
        currentUserRank: currentUserEntry?.rank ?? null,
        totalInLeague: entries.length,
      };
    }

    // Fallback: live query against league_members + profiles
    const { data: members, error: membersError } = await supabaseAdmin
      .from('league_members')
      .select('user_id, weekly_xp, profiles(username, display_name, avatar_url, current_streak)')
      .eq('league_tier', profile.league)
      .eq('week_start', start)
      .order('weekly_xp', { ascending: false });

    if (membersError) {
      throw Errors.internal('Failed to load league members');
    }

    const entries: LeaderboardEntry[] = (members ?? []).map((row, idx) => {
      const p = row.profiles as unknown as {
        username: string;
        display_name: string;
        avatar_url: string | null;
        current_streak: number;
      };

      return {
        rank: idx + 1,
        user_id: row.user_id,
        username: p?.username ?? 'unknown',
        display_name: p?.display_name ?? 'Unknown',
        avatar_url: p?.avatar_url ?? null,
        weekly_xp: row.weekly_xp,
        current_streak: p?.current_streak ?? 0,
        is_current_user: row.user_id === userId,
      };
    });

    const currentUserEntry = entries.find((e) => e.is_current_user);

    return {
      league: profile.league,
      weekStart: start,
      entries,
      currentUserRank: currentUserEntry?.rank ?? null,
      totalInLeague: entries.length,
    };
  },
};
