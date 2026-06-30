import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { env } from '../../config/env';

/**
 * Thin Redis client wrapper. Connects to Upstash via the rediss:// (TLS) URL.
 * M0.2 only needs connectivity (ping); BullMQ queues/workers are added in M0.4.
 * The client is null when REDIS_URL is unset, so the app still boots without Redis.
 */
@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  readonly client: Redis | null;

  constructor() {
    if (env.REDIS_URL) {
      // Eager connect; rediss:// enables TLS automatically (Upstash). Bounded reconnects.
      this.client = new Redis(env.REDIS_URL, {
        maxRetriesPerRequest: 3,
        retryStrategy: (times) => Math.min(times * 200, 2000),
      });
      this.client.on('error', (err) => this.logger.warn(`Redis error: ${err.message}`));
    } else {
      this.client = null;
    }
  }

  isConfigured(): boolean {
    return this.client !== null;
  }

  async ping(): Promise<boolean> {
    if (!this.client) return false;
    try {
      // Bound the ping so a stalled connection can't hang the health check.
      const pong = await Promise.race([
        this.client.ping(),
        new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error('ping timeout')), 3000),
        ),
      ]);
      return pong === 'PONG';
    } catch (err) {
      this.logger.warn(`Redis ping failed: ${(err as Error).message}`);
      return false;
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (this.client) {
      await this.client.quit().catch(() => undefined);
    }
  }
}
