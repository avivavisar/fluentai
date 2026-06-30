import Redis from 'ioredis';
import { config } from './config';

// Redis is optional. When disabled, `redis` is null and callers must guard.
export const redisEnabled: boolean = config.REDIS_ENABLED;

export const redis: Redis | null = redisEnabled
  ? new Redis(config.REDIS_URL, { maxRetriesPerRequest: 2, lazyConnect: true })
  : null;

export async function connectRedis(): Promise<void> {
  if (redis && (redis.status === 'wait' || redis.status === 'end')) {
    await redis.connect();
  }
}
