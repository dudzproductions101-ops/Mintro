import type { FastifyInstance } from 'fastify';
import { leaderboardController } from '../controllers/leaderboardController.js';
import { requireAuth } from '../middleware/auth.js';

export async function leaderboardRoutes(app: FastifyInstance): Promise<void> {
  app.get('/leaderboard/me', { preHandler: requireAuth }, leaderboardController.getMine);
}
