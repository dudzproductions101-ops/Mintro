import { goalRepository, type Goal, type GoalMilestone } from '../repositories/goalRepository.js';
import { gamificationService } from './gamificationService.js';
import { questService } from './questService.js';
import type { CreateGoalInput, UpdateGoalInput } from '../validators/goal.schema.js';
import type { QuestProgressUpdate } from './questService.js';

/** Bonus rewards granted when a savings milestone is crossed. */
const MILESTONE_REWARDS: Record<number, { xp: number; coins: number }> = {
  25: { xp: 25, coins: 50 },
  50: { xp: 50, coins: 100 },
  75: { xp: 75, coins: 150 },
  100: { xp: 200, coins: 500 },
};

export interface ContributionResult {
  goal: Goal;
  newlyReachedMilestones: GoalMilestone[];
  rewardsGranted: { xp: number; coins: number };
  questUpdates: QuestProgressUpdate[];
}

export const goalService = {
  async list(userId: string): Promise<Goal[]> {
    return goalRepository.listForUser(userId);
  },

  async create(userId: string, input: CreateGoalInput): Promise<Goal> {
    return goalRepository.create(userId, input);
  },

  async update(userId: string, goalId: string, input: UpdateGoalInput): Promise<Goal> {
    return goalRepository.update(userId, goalId, input);
  },

  async contribute(userId: string, goalId: string, amount: number): Promise<ContributionResult> {
    const goal = await goalRepository.contribute(userId, goalId, amount);
    const newlyReachedMilestones = await goalRepository.markNewlyReachedMilestones(goal);

    let totalXp = 0;
    let totalCoins = 0;

    for (const milestone of newlyReachedMilestones) {
      const reward = MILESTONE_REWARDS[milestone.percentage];
      if (reward) {
        totalXp += reward.xp;
        totalCoins += reward.coins;
      }
    }

    if (totalXp > 0 || totalCoins > 0) {
      await gamificationService.awardXpAndCoins(userId, totalXp, totalCoins);
    }

    const questUpdates = await questService.incrementByType(userId, 'save_money', amount);

    return {
      goal,
      newlyReachedMilestones,
      rewardsGranted: { xp: totalXp, coins: totalCoins },
      questUpdates,
    };
  },
};
