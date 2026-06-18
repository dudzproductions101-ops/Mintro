import type { FastifyInstance } from 'fastify';
import { questController } from '../controllers/questController.js';
import { requireAuth } from '../middleware/auth.js';

export async function questRoutes(app: FastifyInstance): Promise<void> {
  app.get('/quests/active', { preHandler: requireAuth }, questController.listActive);
  app.post('/quests/:userQuestId/claim', { preHandler: requireAuth }, questController.claim);
}
