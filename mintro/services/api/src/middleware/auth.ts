import type { FastifyReply, FastifyRequest } from 'fastify';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { Errors } from '../utils/errors.js';

export interface AuthenticatedUser {
  id: string;
  email?: string;
  role?: string;
}

declare module 'fastify' {
  interface FastifyRequest {
    user?: AuthenticatedUser;
  }
}

interface SupabaseJwtPayload {
  sub: string;
  email?: string;
  role?: string;
  aud?: string;
  exp?: number;
}

/**
 * Verifies the `Authorization: Bearer <token>` header against Supabase's
 * JWT secret (HS256) and attaches the decoded user to `request.user`.
 *
 * Use as a Fastify `preHandler` on any route that requires authentication.
 */
export async function requireAuth(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
  const header = request.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    throw Errors.unauthorized('Missing or malformed Authorization header');
  }

  const token = header.slice('Bearer '.length).trim();

  try {
    const payload = jwt.verify(token, env.SUPABASE_JWT_SECRET, {
      algorithms: ['HS256'],
    }) as SupabaseJwtPayload;

    if (!payload.sub) {
      throw Errors.unauthorized('Token missing subject claim');
    }

    request.user = {
      id: payload.sub,
      email: payload.email,
      role: payload.role,
    };
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      throw Errors.unauthorized('Token expired');
    }
    if (err instanceof jwt.JsonWebTokenError) {
      throw Errors.unauthorized('Invalid token');
    }
    throw err;
  }
}
