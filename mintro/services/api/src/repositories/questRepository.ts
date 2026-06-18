import { supabaseAdmin } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';

export type QuestType =
  | 'complete_lessons'
  | 'earn_xp'
  | 'save_money'
  | 'maintain_streak'
  | 'complete_path'
  | 'spend_time_learning';

export type QuestPeriod = 'daily' | 'weekly' | 'monthly';

export interface QuestTemplate {
  id: string;
  slug: string;
  title: string;
  description: string | null;
  quest_type: QuestType;
  period: QuestPeriod;
  target_value: number;
  xp_reward: number;
  coin_reward: number;
  icon: string | null;
  is_featured: boolean;
}

export interface UserQuest {
  id: string;
  user_id: string;
  quest_id: string;
  period_start: string;
  period_end: string;
  current_value: number;
  completed: boolean;
  completed_at: string | null;
  claimed: boolean;
  claimed_at: string | null;
  quests?: QuestTemplate;
}

/** Returns the [start, end] date strings (YYYY-MM-DD) for a given period anchored to `now`. */
export function getPeriodRange(period: QuestPeriod, now = new Date()): { start: string; end: string } {
  const toISODate = (d: Date) => d.toISOString().slice(0, 10);

  if (period === 'daily') {
    return { start: toISODate(now), end: toISODate(now) };
  }

  if (period === 'weekly') {
    const day = now.getUTCDay(); // 0 = Sunday
    const diffToMonday = (day + 6) % 7;
    const start = new Date(now);
    start.setUTCDate(now.getUTCDate() - diffToMonday);
    const end = new Date(start);
    end.setUTCDate(start.getUTCDate() + 6);
    return { start: toISODate(start), end: toISODate(end) };
  }

  // monthly
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0));
  return { start: toISODate(start), end: toISODate(end) };
}

export const questRepository = {
  async getAllTemplates(): Promise<QuestTemplate[]> {
    const { data, error } = await supabaseAdmin.from('quests').select('*');

    if (error) {
      throw Errors.internal('Failed to load quest templates');
    }

    return (data ?? []) as QuestTemplate[];
  },

  /**
   * Ensures a `user_quests` row exists for the given template + current period.
   * Idempotent — safe to call on every "open quests screen" request.
   */
  async ensureActiveQuest(userId: string, template: QuestTemplate): Promise<UserQuest> {
    const { start, end } = getPeriodRange(template.period);

    const { data: existing, error: findError } = await supabaseAdmin
      .from('user_quests')
      .select('*')
      .eq('user_id', userId)
      .eq('quest_id', template.id)
      .eq('period_start', start)
      .maybeSingle();

    if (findError) {
      throw Errors.internal('Failed to look up user quest');
    }

    if (existing) {
      return existing as UserQuest;
    }

    const { data: created, error: createError } = await supabaseAdmin
      .from('user_quests')
      .insert({
        user_id: userId,
        quest_id: template.id,
        period_start: start,
        period_end: end,
        current_value: 0,
        completed: false,
        claimed: false,
      })
      .select('*')
      .single();

    if (createError || !created) {
      throw Errors.internal('Failed to create user quest');
    }

    return created as UserQuest;
  },

  async getActiveForUser(userId: string): Promise<UserQuest[]> {
    const { data, error } = await supabaseAdmin
      .from('user_quests')
      .select('*, quests(*)')
      .eq('user_id', userId)
      .order('period_end', { ascending: true });

    if (error) {
      throw Errors.internal('Failed to load user quests');
    }

    return (data ?? []) as UserQuest[];
  },

  async incrementProgress(userQuestId: string, amount: number, target: number): Promise<UserQuest> {
    const { data: current, error: fetchError } = await supabaseAdmin
      .from('user_quests')
      .select('*')
      .eq('id', userQuestId)
      .single();

    if (fetchError || !current) {
      throw Errors.internal('Failed to load user quest for progress update');
    }

    if (current.completed) {
      return current as UserQuest;
    }

    const newValue = Math.min(current.current_value + amount, target);
    const isNowComplete = newValue >= target;

    const { data, error } = await supabaseAdmin
      .from('user_quests')
      .update({
        current_value: newValue,
        completed: isNowComplete,
        completed_at: isNowComplete ? new Date().toISOString() : null,
      })
      .eq('id', userQuestId)
      .select('*')
      .single();

    if (error || !data) {
      throw Errors.internal('Failed to update quest progress');
    }

    return data as UserQuest;
  },

  async claim(userId: string, userQuestId: string): Promise<UserQuest> {
    const { data: quest, error: fetchError } = await supabaseAdmin
      .from('user_quests')
      .select('*')
      .eq('id', userQuestId)
      .eq('user_id', userId)
      .single();

    if (fetchError || !quest) {
      throw Errors.notFound('Quest not found');
    }

    if (!quest.completed) {
      throw Errors.badRequest('Quest is not yet completed');
    }

    if (quest.claimed) {
      throw Errors.conflict('Quest reward already claimed');
    }

    const { data, error } = await supabaseAdmin
      .from('user_quests')
      .update({ claimed: true, claimed_at: new Date().toISOString() })
      .eq('id', userQuestId)
      .select('*')
      .single();

    if (error || !data) {
      throw Errors.internal('Failed to claim quest reward');
    }

    return data as UserQuest;
  },
};
