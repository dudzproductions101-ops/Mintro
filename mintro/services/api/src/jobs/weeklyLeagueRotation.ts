import { supabaseAdmin } from '../config/supabase.js';
import { getPeriodRange } from '../repositories/questRepository.js';
import { pushService } from '../notifications/pushService.js';
import { logger } from '../utils/logger.js';

const LEAGUE_ORDER = ['copper', 'bronze', 'silver', 'gold', 'emerald', 'diamond', 'master'] as const;
type LeagueTier = (typeof LEAGUE_ORDER)[number];

function nextLeague(tier: LeagueTier): LeagueTier | null {
  const idx = LEAGUE_ORDER.indexOf(tier);
  return idx >= 0 && idx < LEAGUE_ORDER.length - 1 ? LEAGUE_ORDER[idx + 1] : null;
}

function previousLeague(tier: LeagueTier): LeagueTier | null {
  const idx = LEAGUE_ORDER.indexOf(tier);
  return idx > 0 ? LEAGUE_ORDER[idx - 1] : null;
}

/**
 * Runs Sunday 23:55 UTC.
 *
 * For each league tier:
 *  1. Ranks members by weekly_xp for the week that just ended.
 *  2. Writes a `leaderboard_snapshots` row per member (for fast client reads).
 *  3. Promotes the top N members to the next tier up, demotes the bottom M
 *     to the tier below (Master has no promotion, Copper has no demotion).
 *  4. Sends promotion/demotion push notifications.
 *  5. Seeds `league_members` rows for the new week at each member's
 *     (possibly updated) tier with weekly_xp reset to 0.
 */
export async function runWeeklyLeagueRotation(): Promise<void> {
  logger.info('Running weekly league rotation');

  const { start: endingWeek } = getPeriodRange('weekly');

  const { data: leagueDefs, error: leagueError } = await supabaseAdmin
    .from('leagues')
    .select('*');

  if (leagueError || !leagueDefs) {
    logger.error({ err: leagueError }, 'Failed to load league definitions');
    return;
  }

  const nextWeekStart = new Date(endingWeek);
  nextWeekStart.setUTCDate(nextWeekStart.getUTCDate() + 7);
  const nextWeekStartStr = nextWeekStart.toISOString().slice(0, 10);

  for (const league of leagueDefs) {
    const tier = league.tier as LeagueTier;

    const { data: members, error: membersError } = await supabaseAdmin
      .from('league_members')
      .select('user_id, weekly_xp, profiles(username, display_name, avatar_url, current_streak)')
      .eq('league_tier', tier)
      .eq('week_start', endingWeek)
      .order('weekly_xp', { ascending: false });

    if (membersError) {
      logger.error({ err: membersError, tier }, 'Failed to load league members');
      continue;
    }

    const sorted = members ?? [];

    // Write leaderboard snapshot
    const snapshotRows = sorted.map((m, idx) => {
      const p = m.profiles as unknown as {
        username: string;
        display_name: string;
        avatar_url: string | null;
        current_streak: number;
      };

      return {
        league_tier: tier,
        week_start: endingWeek,
        user_id: m.user_id,
        username: p?.username ?? 'unknown',
        display_name: p?.display_name ?? 'Unknown',
        avatar_url: p?.avatar_url ?? null,
        weekly_xp: m.weekly_xp,
        rank: idx + 1,
        current_streak: p?.current_streak ?? 0,
      };
    });

    if (snapshotRows.length > 0) {
      const { error: snapshotError } = await supabaseAdmin
        .from('leaderboard_snapshots')
        .upsert(snapshotRows, { onConflict: 'league_tier,week_start,user_id' });

      if (snapshotError) {
        logger.error({ err: snapshotError, tier }, 'Failed to write leaderboard snapshot');
      }
    }

    const promotionCount = league.promotion_count as number;
    const demotionCount = league.demotion_count as number;
    const promoteUp = nextLeague(tier);
    const demoteDown = previousLeague(tier);

    for (let idx = 0; idx < sorted.length; idx++) {
      const member = sorted[idx];
      let newTier: LeagueTier = tier;
      let promoted = false;
      let demoted = false;

      if (promoteUp && idx < promotionCount) {
        newTier = promoteUp;
        promoted = true;
      } else if (demoteDown && idx >= sorted.length - demotionCount && sorted.length > promotionCount) {
        newTier = demoteDown;
        demoted = true;
      }

      // Update final state of the ending week's row
      await supabaseAdmin
        .from('league_members')
        .update({
          rank_in_league: idx + 1,
          promoted,
          demoted,
        })
        .eq('user_id', member.user_id)
        .eq('week_start', endingWeek);

      // Update the user's current league on their profile
      if (newTier !== tier) {
        await supabaseAdmin.from('profiles').update({ league: newTier }).eq('id', member.user_id);

        await pushService.sendToUser({
          userId: member.user_id,
          type: promoted ? 'league_promotion' : 'league_demotion',
          title: promoted ? '🎉 Promoted!' : 'League update',
          body: promoted
            ? `You've been promoted to the ${newTier.charAt(0).toUpperCase() + newTier.slice(1)} League!`
            : `You've moved down to the ${newTier.charAt(0).toUpperCase() + newTier.slice(1)} League. Keep going to climb back up!`,
        });
      }

      // Seed next week's league_members row
      await supabaseAdmin.from('league_members').insert({
        user_id: member.user_id,
        league_tier: newTier,
        week_start: nextWeekStartStr,
        weekly_xp: 0,
      });
    }
  }

  logger.info('Weekly league rotation complete');
}
