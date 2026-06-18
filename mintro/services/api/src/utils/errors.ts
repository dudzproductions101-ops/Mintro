export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown;

  constructor(message: string, statusCode: number, code: string, details?: unknown) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

export const Errors = {
  unauthorized: (message = 'Unauthorized') => new AppError(message, 401, 'UNAUTHORIZED'),
  forbidden: (message = 'Forbidden') => new AppError(message, 403, 'FORBIDDEN'),
  notFound: (message = 'Resource not found') => new AppError(message, 404, 'NOT_FOUND'),
  badRequest: (message: string, details?: unknown) =>
    new AppError(message, 400, 'BAD_REQUEST', details),
  conflict: (message: string) => new AppError(message, 409, 'CONFLICT'),
  tooManyRequests: (message = 'Too many requests') =>
    new AppError(message, 429, 'RATE_LIMITED'),
  internal: (message = 'Internal server error') => new AppError(message, 500, 'INTERNAL'),
};
