import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { jwtVerify, createRemoteJWKSet, decodeProtectedHeader } from 'jose';
import type { User } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import { env } from '../config/env';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  // Legacy HS256 shared secret (Supabase JWT Settings).
  private readonly secret: Uint8Array | null = env.SUPABASE_JWT_SECRET
    ? new TextEncoder().encode(env.SUPABASE_JWT_SECRET)
    : null;
  // Modern Supabase signs user access tokens with asymmetric keys (ES256/RS256) exposed via JWKS.
  // Keys are fetched + cached by jose. Support both schemes.
  private readonly jwks: ReturnType<typeof createRemoteJWKSet> | null = AuthService.makeJwks();

  // Never let a bad/blank SUPABASE_URL crash the app at boot — JWKS just stays unavailable.
  private static makeJwks(): ReturnType<typeof createRemoteJWKSet> | null {
    if (!env.SUPABASE_URL) return null;
    try {
      return createRemoteJWKSet(new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`));
    } catch {
      return null;
    }
  }

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Verify a Supabase access token (HS256 secret or asymmetric via JWKS) and map it to a local
   * User row, creating the user on first sight (JIT provisioning). Supabase is the source of truth.
   */
  async verifyAndMapUser(token: string): Promise<User> {
    let payload: Record<string, unknown>;
    try {
      const alg = decodeProtectedHeader(token).alg ?? '';
      if (alg.startsWith('HS')) {
        if (!this.secret) throw new Error('SUPABASE_JWT_SECRET missing for HS256 token');
        payload = (await jwtVerify(token, this.secret)).payload as Record<string, unknown>;
      } else {
        if (!this.jwks) throw new Error('SUPABASE_URL missing for JWKS verification');
        payload = (await jwtVerify(token, this.jwks)).payload as Record<string, unknown>;
      }
    } catch (err) {
      this.logger.warn(`Token verification failed: ${(err as Error).message}`);
      throw new UnauthorizedException('Invalid or expired token.');
    }

    const supabaseId = typeof payload.sub === 'string' ? payload.sub : '';
    const email = typeof payload.email === 'string' ? payload.email : '';
    if (!supabaseId) {
      throw new UnauthorizedException('Token is missing a subject (sub) claim.');
    }

    // 1) Already linked by supabaseId.
    const existing = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (existing) {
      return existing;
    }

    // 2) Same email exists from a prior flow — link it to this Supabase identity.
    if (email) {
      const byEmail = await this.prisma.user.findUnique({ where: { email } });
      if (byEmail) {
        return this.prisma.user.update({
          where: { id: byEmail.id },
          data: { supabaseId, lastActiveAt: new Date() },
        });
      }
    }

    // 3) First time — create the local user.
    return this.prisma.user.create({
      data: {
        supabaseId,
        email: email || `${supabaseId}@no-email.fluentai.local`,
      },
    });
  }
}
