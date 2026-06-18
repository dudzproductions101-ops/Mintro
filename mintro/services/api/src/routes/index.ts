import type { FastifyInstance } from 'fastify';
import { lessonRoutes } from './lessons.routes.js';
import { goalRoutes } from './goals.routes.js';
import { questRoutes } from './quests.routes.js';
import { leaderboardRoutes } from './leaderboard.routes.js';

export async function registerRoutes(app: FastifyInstance): Promise<void> {
  app.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

  await app.register(lessonRoutes, { prefix: '/api/v1' });
  await app.register(goalRoutes, { prefix: '/api/v1' });
  await app.register(questRoutes, { prefix: '/api/v1' });
  await app.register(leaderboardRoutes, { prefix: '/api/v1' });
}
