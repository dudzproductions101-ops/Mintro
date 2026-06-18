import { z } from 'zod';

export const createGoalSchema = z.object({
  name: z.string().trim().min(1).max(60),
  icon: z.string().max(40).optional(),
  targetAmount: z.number().positive().max(10_000_000),
  currency: z.string().length(3).default('EUR'),
  deadline: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'deadline must be YYYY-MM-DD')
    .optional(),
  initialAmount: z.number().min(0).default(0),
});

export const contributeToGoalSchema = z.object({
  amount: z.number().positive().max(10_000_000),
});

export const updateGoalSchema = z.object({
  name: z.string().trim().min(1).max(60).optional(),
  icon: z.string().max(40).optional(),
  targetAmount: z.number().positive().max(10_000_000).optional(),
  deadline: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'deadline must be YYYY-MM-DD')
    .nullable()
    .optional(),
});

export type CreateGoalInput = z.infer<typeof createGoalSchema>;
export type ContributeToGoalInput = z.infer<typeof contributeToGoalSchema>;
export type UpdateGoalInput = z.infer<typeof updateGoalSchema>;
