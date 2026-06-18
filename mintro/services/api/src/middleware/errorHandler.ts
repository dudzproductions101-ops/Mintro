import type { FastifyError, FastifyReply, FastifyRequest } from 'fastify';
import { ZodError } from 'zod';
import { AppError } from '../utils/errors.js';
import { logger } from '../utils/logger.js';

export function errorHandler(
  error: FastifyError | AppError | ZodError | Error,
  request: FastifyRequest,
  reply: FastifyReply,
): void {
  // Zod validation errors → 400 with field-level details
  if (error instanceof ZodError) {
    reply.status(400).send({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: error.flatten(),
      },
    });
    return;
  }

  // Known application errors
  if (error instanceof AppError) {
    if (error.statusCode >= 500) {
      logger.error({ err: error, path: request.url }, error.message);
    } else {
      logger.warn({ err: error, path: request.url }, error.message);
    }

    reply.status(error.statusCode).send({
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
      },
    });
    return;
  }

  // Fastify built-in errors (e.g. rate limit, malformed JSON)
  const fastifyErr = error as FastifyError;
  if (fastifyErr.statusCode) {
    reply.status(fastifyErr.statusCode).send({
      error: {
        code: fastifyErr.code ?? 'ERROR',
        message: fastifyErr.message,
      },
    });
    return;
  }

  // Fallback: unexpected error
  logger.error({ err: error, path: request.url }, 'Unhandled error');
  reply.status(500).send({
    error: {
      code: 'INTERNAL',
      message: 'Something went wrong. Please try again.',
    },
  });
}
