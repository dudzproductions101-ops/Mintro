import type { FastifyReply, FastifyRequest } from 'fastify';
import { lessonService } from '../services/lessonService.js';
import { completeLessonSchema } from '../validators/lesson.schema.js';
import { Errors } from '../utils/errors.js';

export const lessonController = {
  async complete(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user!.id;
    const { lessonId } = request.params as { lessonId: string };

    if (!lessonId) {
      throw Errors.badRequest('lessonId is required');
    }

    const input = completeLessonSchema.parse(request.body);

    const result = await lessonService.completeLesson(userId, lessonId, input);

    reply.send({ data: result });
  },
};
