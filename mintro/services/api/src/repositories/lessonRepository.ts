import { supabaseAdmin } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';

export interface QuizQuestion {
  id: string;
  type: 'multiple_choice' | 'true_false' | 'match_pairs' | 'drag_drop' | 'scenario';
  prompt: string;
  options?: { id: string; label: string }[];
  pairs?: { left: string; right: string }[];
  correctAnswer: string | string[] | Record<string, string>;
  explanation?: string;
}

export interface LessonContent {
  intro?: string;
  questions: QuizQuestion[];
  passingScore: number; // 0-100
  simulation?: {
    startingAmount: number;
    choices: { id: string; label: string; outcomeRange: [number, number] }[];
  };
}

export interface Lesson {
  id: string;
  path_id: string;
  slug: string;
  title: string;
  description: string | null;
  lesson_type: string;
  icon: string | null;
  xp_reward: number;
  coin_reward: number;
  content: LessonContent;
  is_premium: boolean;
}

export interface UserLesson {
  id: string;
  user_id: string;
  lesson_id: string;
  completed_at: string | null;
  score: number | null;
  xp_earned: number;
  coins_earned: number;
  attempts: number;
}

export const lessonRepository = {
  async getById(lessonId: string): Promise<Lesson> {
    const { data, error } = await supabaseAdmin
      .from('lessons')
      .select('*')
      .eq('id', lessonId)
      .single();

    if (error || !data) {
      throw Errors.notFound('Lesson not found');
    }

    return data as Lesson;
  },

  async getUserLesson(userId: string, lessonId: string): Promise<UserLesson | null> {
    const { data, error } = await supabaseAdmin
      .from('user_lessons')
      .select('*')
      .eq('user_id', userId)
      .eq('lesson_id', lessonId)
      .maybeSingle();

    if (error) {
      throw Errors.internal('Failed to load user lesson record');
    }

    return data as UserLesson | null;
  },

  async upsertCompletion(params: {
    userId: string;
    lessonId: string;
    score: number;
    xpEarned: number;
    coinsEarned: number;
  }): Promise<UserLesson> {
    const existing = await this.getUserLesson(params.userId, params.lessonId);

    const { data, error } = await supabaseAdmin
      .from('user_lessons')
      .upsert(
        {
          user_id: params.userId,
          lesson_id: params.lessonId,
          completed_at: new Date().toISOString(),
          score: params.score,
          xp_earned: params.xpEarned,
          coins_earned: params.coinsEarned,
          attempts: (existing?.attempts ?? 0) + 1,
        },
        { onConflict: 'user_id,lesson_id' },
      )
      .select('*')
      .single();

    if (error || !data) {
      throw Errors.internal('Failed to record lesson completion');
    }

    return data as UserLesson;
  },

  async countLessonsCompletedToday(userId: string): Promise<number> {
    const startOfDay = new Date();
    startOfDay.setUTCHours(0, 0, 0, 0);

    const { count, error } = await supabaseAdmin
      .from('user_lessons')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .gte('completed_at', startOfDay.toISOString());

    if (error) {
      throw Errors.internal('Failed to count completed lessons');
    }

    return count ?? 0;
  },
};
