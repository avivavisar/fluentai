import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import type { User } from '@prisma/client';

/** Injects the authenticated User attached by AuthGuard. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): User => {
    const req = context.switchToHttp().getRequest<Request & { user: User }>();
    return req.user;
  },
);
