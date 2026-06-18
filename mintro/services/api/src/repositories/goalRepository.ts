import { supabaseAdmin } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';
import type { CreateGoalInput, UpdateGoalInput } from '../validators/goal.schema.js';

export interface Goal {
  id: string;
  user_id: string;
  name: string;
  icon: string | null;
  target_amount: number;
  current_amount: number;
  currency: string;
  deadline: string | null;
  status: 'active' | 'completed' | 'archived';
  created_at: string;
  updated_at: string;
}

export interface GoalMilestone {
  id: string;
  goal_id: string;
  percentage: number;
  reached: boolean;
  reached_at: string | null;
}

const MILESTONE_PERCENTAGES = [25, 50, 75, 100];

export const goalRepository = {
  async listForUser(userId: string): Promise<Goal[]> {
    const { data, error } = await supabaseAdmin
      .from('goals')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw Errors.internal('Failed to load goals');
    }

    return (data ?? []) as Goal[];
  },

  async getById(userId: string, goalId: string): Promise<Goal> {
    const { data, error } = await supabaseAdmin
      .from('goals')
      .select('*')
      .eq('id', goalId)
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      throw Errors.notFound('Goal not found');
    }

    return data as Goal;
  },

  async create(userId: string, input: CreateGoalInput): Promise<Goal> {
    const { data, error } = await supabaseAdmin
      .from('goals')
      .insert({
        user_id: userId,
        name: input.name,
        icon: input.icon ?? null,
        target_amount: input.targetAmount,
        current_amount: input.initialAmount,
        currency: input.currency,
        deadline: input.deadline ?? null,
        status: 'active',
      })
      .select('*')
      .single();

    if (error || !data) {
      throw Errors.internal('Failed to create goal');
    }

    const goal = data as Goal;

    const milestoneRows = MILESTONE_PERCENTAGES.map((percentage) => ({
      goal_id: goal.id,
      percentage,
      reached: false,
    }));

    const { error: milestoneError } = await supabaseAdmin
      .from('goal_milestones')
      .insert(milestoneRows);

    if (milestoneError) {
      throw Errors.internal('Failed to create goal milestones');
    }

    return goal;
  },

  async update(userId: string, goalId: string, input: UpdateGoalInput): Promise<Goal> {
    const updatePayload: Record<string, unknown> = {};
    if (input.name !== undefined) updatePayload.name = input.name;
    if (input.icon !== undefined) updatePayload.icon = input.icon;
    if (input.targetAmount !== undefined) updatePayload.target_amount = input.targetAmount;
    if (input.deadline !== undefined) updatePayload.deadline = input.deadline;

    const { data, error } = await supabaseAdmin
      .from('goals')
      .update(updatePayload)
      .eq('id', goalId)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error || !data) {
      throw Errors.notFound('Goal not found');
    }

    return data as Goal;
  },

  async contribute(userId: string, goalId: string, amount: number): Promise<Goal> {
    const goal = await this.getById(userId, goalId);

    if (goal.status !== 'active') {
      throw Errors.badRequest('Cannot contribute to a goal that is not active');
    }

    const newAmount = Math.min(goal.current_amount + amount, goal.target_amount);
    const newStatus = newAmount >= goal.target_amount ? 'completed' : 'active';

    const { data, error } = await supabaseAdmin
      .from('goals')
      .update({ current_amount: newAmount, status: newStatus })
      .eq('id', goalId)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error || !data) {
      throw Errors.internal('Failed to update goal progress');
    }

    return data as Goal;
  },

  async getMilestones(goalId: string): Promise<GoalMilestone[]> {
    const { data, error } = await supabaseAdmin
      .from('goal_milestones')
      .select('*')
      .eq('goal_id', goalId)
      .order('percentage', { ascending: true });

    if (error) {
      throw Errors.internal('Failed to load goal milestones');
    }

    return (data ?? []) as GoalMilestone[];
  },

  /**
   * Marks any milestones newly reached given the goal's new progress percentage.
   * Returns the list of milestones that were newly crossed (for reward/animation triggers).
   */
  async markNewlyReachedMilestones(goal: Goal): Promise<GoalMilestone[]> {
    const progressPct = (goal.current_amount / goal.target_amount) * 100;
    const milestones = await this.getMilestones(goal.id);

    const newlyReached: GoalMilestone[] = [];

    for (const milestone of milestones) {
      if (!milestone.reached && progressPct >= milestone.percentage) {
        const { data, error } = await supabaseAdmin
          .from('goal_milestones')
          .update({ reached: true, reached_at: new Date().toISOString() })
          .eq('id', milestone.id)
          .select('*')
          .single();

        if (error || !data) {
          throw Errors.internal('Failed to update goal milestone');
        }

        newlyReached.push(data as GoalMilestone);
      }
    }

    return newlyReached;
  },
};
