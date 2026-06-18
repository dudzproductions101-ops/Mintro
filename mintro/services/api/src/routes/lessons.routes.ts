import type { FastifyInstance } from 'fastify';
import { lessonController } from '../controllers/lessonController.js';
import { requireAuth } from '../middleware/auth.js';

export async function lessonRoutes(app: FastifyInstance): Promise<void> {
  app.post(
    '/lessons/:lessonId/complete',
    { preHandler: requireAuth },
    lessonController.complete,
  );
}
