import type { FastifyReply, FastifyRequest } from 'fastify';
import { goalService } from '../services/goalService.js';
import {
  contributeToGoalSchema,
  createGoalSchema,
  updateGoalSchema,
} from '../validators/goal.schema.js';
import { Errors } from '../utils/errors.js';

export const goalController = {
  async list(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const goals = await goalService.list(userId);
    reply.send({ data: goals });
  },

  async create(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const input = createGoalSchema.parse(request.body);
    const goal = await goalService.create(userId, input);
    reply.status(201).send({ data: goal });
  },

  async update(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const { goalId } = request.params as { goalId: string };

    if (!goalId) {
      throw Errors.badRequest('goalId is required');
    }

    const input = updateGoalSchema.parse(request.body);
    const goal = await goalService.update(userId, goalId, input);
    reply.send({ data: goal });
  },

  async contribute(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const { goalId } = request.params as { goalId: string };

    if (!goalId) {
      throw Errors.badRequest('goalId is required');
    }

    const { amount } = contributeToGoalSchema.parse(request.body);
    const result = await goalService.contribute(userId, goalId, amount);
    reply.send({ data: result });
  },
};
