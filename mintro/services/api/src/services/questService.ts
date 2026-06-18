import { questRepository, type QuestType, type UserQuest } from '../repositories/questRepository.js';

export interface QuestProgressUpdate {
  userQuest: UserQuest;
  justCompleted: boolean;
}

/**
 * Evaluates all of a user's active quests of the given types and increments
 * progress by `amount`. Used after lesson completion (complete_lessons,
 * earn_xp), goal contributions (save_money), and streak updates
 * (maintain_streak).
 */
export const questService = {
  async ensureAllActiveQuests(userId: string): Promise<UserQuest[]> {
    const templates = await questRepository.getAllTemplates();
    const ensured: UserQuest[] = [];

    for (const template of templates) {
      ensured.push(await questRepository.ensureActiveQuest(userId, template));
    }

    return ensured;
  },

  async incrementByType(
    userId: string,
    questType: QuestType,
    amount: number,
  ): Promise<QuestProgressUpdate[]> {
    if (amount <= 0) return [];

    const templates = await questRepository.getAllTemplates();
    const relevant = templates.filter((t) => t.quest_type === questType);

    const updates: QuestProgressUpdate[] = [];

    for (const template of relevant) {
      const userQuest = await questRepository.ensureActiveQuest(userId, template);

      if (userQuest.completed) continue;

      const wasComplete = userQuest.completed;
      const updated = await questRepository.incrementProgress(
        userQuest.id,
        amount,
        template.target_value,
      );

      updates.push({
        userQuest: { ...updated, quests: template },
        justCompleted: !wasComplete && updated.completed,
      });
    }

    return updates;
  },

  async getActiveQuests(userId: string): Promise<UserQuest[]> {
    await this.ensureAllActiveQuests(userId);
    return questRepository.getActiveForUser(userId);
  },

  async claimReward(userId: string, userQuestId: string) {
    return questRepository.claim(userId, userQuestId);
  },

  /**
   * Sets maintain_streak quest progress to exactly `streakDays`.
   * Called after a confirmed streak extension so the quest value
   * always matches the real streak count rather than accumulating
   * wrong deltas if a user completes multiple lessons in one day.
   */
  async setStreakProgress(userId: string, streakDays: number): Promise<QuestProgressUpdate[]> {
    const templates = await questRepository.getAllTemplates();
    const streakTemplates = templates.filter((t) => t.quest_type === 'maintain_streak');
    const updates: QuestProgressUpdate[] = [];

    for (const template of streakTemplates) {
      const userQuest = await questRepository.ensureActiveQuest(userId, template);
      if (userQuest.completed) continue;

      // Calculate delta: we want current_value to become streakDays,
      // but incrementProgress adds to existing value, so we send the
      // difference. If current_value is somehow ahead (shouldn't happen
      // with a single cron-driven counter), we clamp to 0 change.
      const delta = Math.max(0, streakDays - userQuest.current_value);
      if (delta === 0) continue;

      const wasComplete = userQuest.completed;
      const updated = await questRepository.incrementProgress(
        userQuest.id,
        delta,
        template.target_value,
      );

      updates.push({
        userQuest: { ...updated, quests: template },
        justCompleted: !wasComplete && updated.completed,
      });
    }

    return updates;
  },
};
