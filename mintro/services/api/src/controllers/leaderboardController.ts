import type { FastifyReply, FastifyRequest } from 'fastify';
import { leaderboardRepository } from '../repositories/leaderboardRepository.js';

export const leaderboardController = {
  async getMine(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const result = await leaderboardRepository.getForUser(userId);
    reply.send({ data: result });
  },
};
