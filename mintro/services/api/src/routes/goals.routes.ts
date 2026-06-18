import type { FastifyInstance } from 'fastify';
import { goalController } from '../controllers/goalController.js';
import { requireAuth } from '../middleware/auth.js';

export async function goalRoutes(app: FastifyInstance): Promise<void> {
  app.get('/goals', { preHandler: requireAuth }, goalController.list);
  app.post('/goals', { preHandler: requireAuth }, goalController.create);
  app.patch('/goals/:goalId', { preHandler: requireAuth }, goalController.update);
  app.post('/goals/:goalId/contribute', { preHandler: requireAuth }, goalController.contribute);
}
