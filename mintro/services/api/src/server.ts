import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import { env } from './config/env.js';
import { logger } from './utils/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { registerRoutes } from './routes/index.js';
import { startScheduledJobs } from './jobs/scheduler.js';

async function buildServer() {
  const app = Fastify({
    logger,
    trustProxy: true,
  });

  await app.register(helmet);

  await app.register(cors, {
    origin: env.ALLOWED_ORIGINS.length > 0 ? env.ALLOWED_ORIGINS : true,
    credentials: true,
  });

  await app.register(rateLimit, {
    max: env.RATE_LIMIT_MAX,
    timeWindow: env.RATE_LIMIT_WINDOW_MS,
    keyGenerator: (request) => request.user?.id ?? request.ip,
  });

  app.setErrorHandler(errorHandler);

  await registerRoutes(app);

  return app;
}

async function start() {
  const app = await buildServer();

  try {
    await app.listen({ port: env.PORT, host: '0.0.0.0' });
    logger.info(`Mintro API listening on port ${env.PORT} (${env.NODE_ENV})`);

    if (env.NODE_ENV === 'production') {
      startScheduledJobs();
    } else {
      logger.info('Scheduled jobs skipped in non-production environment');
    }
  } catch (err) {
    logger.error({ err }, 'Failed to start server');
    process.exit(1);
  }
}

start();
