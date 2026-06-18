import { z } from 'zod';

/**
 * A single answer submitted by the user for one quiz question.
 * `value` shape depends on the lesson's question type:
 *  - multiple_choice / true_false: string (selected option id)
 *  - match_pairs: Record<string, string> (left id -> right id)
 *  - drag_drop: string[] (ordered token ids)
 *  - simulation / scenario: string (selected choice id)
 */
export const quizAnswerSchema = z.object({
  questionId: z.string().min(1),
  value: z.union([z.string(), z.array(z.string()), z.record(z.string(), z.string())]),
});

export const completeLessonSchema = z.object({
  answers: z.array(quizAnswerSchema).default([]),
  timeSpentSeconds: z.number().int().min(0).max(3600).default(0),
});

export type CompleteLessonInput = z.infer<typeof completeLessonSchema>;
export type QuizAnswer = z.infer<typeof quizAnswerSchema>;
