import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { env } from '../../config/env';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit(): Promise<void> {
    // Connect lazily; a missing/placeholder DATABASE_URL must not crash boot (health reports it).
    try {
      await this.$connect();
    } catch (err) {
      this.logger.warn(
        `Database not reachable yet (${(err as Error).message}). /health will report db: down.`,
      );
    }
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }

  isConfigured(): boolean {
    const url = env.DATABASE_URL;
    // Real URL only — not the placeholder default and not an unfilled .env template (<ref>, <password>).
    return url.length > 0 && !url.includes('placeholder') && !url.includes('<');
  }
}
