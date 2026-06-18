import { lessonRepository, type LessonContent, type QuizQuestion } from '../repositories/lessonRepository.js';
import { gamificationService } from './gamificationService.js';
import { questService } from './questService.js';
import type { CompleteLessonInput, QuizAnswer } from '../validators/lesson.schema.js';
import { Errors } from '../utils/errors.js';
import type { QuestProgressUpdate } from './questService.js';

export interface LessonCompletionResult {
  passed: boolean;
  score: number;
  correctCount: number;
  totalQuestions: number;
  xpEarned: number;
  coinsEarned: number;
  xp: {
    newTotalXp: number;
    newLevel: number;
    leveledUp: boolean;
  };
  coins: {
    newTotal: number;
  };
  streak: {
    currentStreak: number;
    longestStreak: number;
    extended: boolean;
  };
  questUpdates: QuestProgressUpdate[];
  questionResults: { questionId: string; correct: boolean; explanation?: string }[];
}

/** Scores a single question against the submitted answer. */
function scoreQuestion(question: QuizQuestion, answer: QuizAnswer | undefined): boolean {
  if (!answer) return false;

  switch (question.type) {
    case 'multiple_choice':
    case 'true_false':
    case 'scenario': {
      return answer.value === question.correctAnswer;
    }
    case 'drag_drop': {
      const expected = question.correctAnswer as string[];
      const submitted = answer.value as string[];
      return (
        Array.isArray(submitted) &&
        submitted.length === expected.length &&
        submitted.every((v, i) => v === expected[i])
      );
    }
    case 'match_pairs': {
      const expected = question.correctAnswer as Record<string, string>;
      const submitted = answer.value as Record<string, string>;
      if (typeof submitted !== 'object') return false;
      const keys = Object.keys(expected);
      return keys.every((k) => submitted[k] === expected[k]);
    }
    default:
      return false;
  }
}

export const lessonService = {
  async completeLesson(
    userId: string,
    lessonId: string,
    input: CompleteLessonInput,
  ): Promise<LessonCompletionResult> {
    const lesson = await lessonRepository.getById(lessonId);
    const content = lesson.content as LessonContent;
    const questions = content.questions ?? [];

    if (questions.length === 0) {
      throw Errors.badRequest('Lesson has no questions configured');
    }

    const answersByQuestionId = new Map(input.answers.map((a) => [a.questionId, a]));

    const questionResults = questions.map((q) => {
      const correct = scoreQuestion(q, answersByQuestionId.get(q.id));
      return { questionId: q.id, correct, explanation: q.explanation };
    });

    const correctCount = questionResults.filter((r) => r.correct).length;
    const score = Math.round((correctCount / questions.length) * 100);
    const passingScore = content.passingScore ?? 80;
    const passed = score >= passingScore;

    const previousAttempt = await lessonRepository.getUserLesson(userId, lessonId);
    const alreadyCompleted = !!previousAttempt?.completed_at;

    // Rewards: full reward on first-ever pass. Reduced (25%) reward on
    // subsequent passes to discourage XP farming via repeated retries
    // while still rewarding review/reinforcement.
    let xpEarned = 0;
    let coinsEarned = 0;

    if (passed) {
      const multiplier = alreadyCompleted ? 0.25 : 1;
      xpEarned = Math.round(lesson.xp_reward * multiplier);
      coinsEarned = Math.round(lesson.coin_reward * multiplier);
    }

    await lessonRepository.upsertCompletion({
      userId,
      lessonId,
      score,
      xpEarned,
      coinsEarned,
    });

    let xpResult = { newTotalXp: 0, newLevel: 0, newCoins: 0, leveledUp: false };
    let streakResult = { currentStreak: 0, longestStreak: 0, streakExtended: false };
    let questUpdates: QuestProgressUpdate[] = [];

    if (passed && xpEarned > 0) {
      const isFirstToday = await gamificationService.isFirstActivityToday(userId);

      xpResult = await gamificationService.awardXpAndCoins(userId, xpEarned, coinsEarned);

      if (isFirstToday) {
        streakResult = await gamificationService.updateStreak(userId);
      }

      // Quest progress: earn_xp always; complete_lessons only counts first-ever passes
      const xpQuestUpdates = await questService.incrementByType(userId, 'earn_xp', xpEarned);
      questUpdates = [...xpQuestUpdates];

      if (!alreadyCompleted) {
        const lessonQuestUpdates = await questService.incrementByType(
          userId,
          'complete_lessons',
          1,
        );
        questUpdates = [...questUpdates, ...lessonQuestUpdates];
      }

      // maintain_streak quests track the current consecutive-day count —
      // increment by the new streak value minus the previous known value
      // (which is 1 for a new streak, or the full streak count each day
      // it extends). Simplest safe approach: set current_value to the new
      // streak count directly via a dedicated helper path. Since
      // questRepository.incrementProgress uses Math.min(current + amount,
      // target), we pass the new streak value as the amount and reset from 0.
      if (streakResult.streakExtended && streakResult.currentStreak > 0) {
        const streakQuestUpdates = await questService.setStreakProgress(
          userId,
          streakResult.currentStreak,
        );
        questUpdates = [...questUpdates, ...streakQuestUpdates];
      }
    }

    return {
      passed,
      score,
      correctCount,
      totalQuestions: questions.length,
      xpEarned,
      coinsEarned,
      xp: {
        newTotalXp: xpResult.newTotalXp,
        newLevel: xpResult.newLevel,
        leveledUp: xpResult.leveledUp,
      },
      coins: {
        newTotal: xpResult.newCoins,
      },
      streak: {
        currentStreak: streakResult.currentStreak,
        longestStreak: streakResult.longestStreak,
        extended: streakResult.streakExtended,
      },
      questUpdates,
      questionResults,
    };
  },
};
