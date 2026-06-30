import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { AuthService } from './auth.service';

/**
 * Protects routes: requires a `Bearer <supabase-access-token>` header, verifies it,
 * maps it to a local User, and attaches the user to the request.
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly auth: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const header = req.headers['authorization'];
    if (!header || !header.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token.');
    }
    const token = header.slice('Bearer '.length).trim();
    // Attach for @CurrentUser() and downstream handlers.
    (req as Request & { user?: unknown }).user = await this.auth.verifyAndMapUser(token);
    return true;
  }
}
