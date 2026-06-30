import type { RedisOptions } from 'ioredis';
import { env } from '../config/env';

/**
 * Build ioredis options for BullMQ from REDIS_URL (Upstash rediss://).
 * BullMQ requires `maxRetriesPerRequest: null` for its blocking connections,
 * which is why we don't reuse the health-check client (it sets a finite value).
 */
export function buildBullConnection(): RedisOptions {
  if (!env.REDIS_URL) {
    throw new Error('REDIS_URL is required to run the job queue (BullMQ).');
  }
  const url = new URL(env.REDIS_URL);
  return {
    host: url.hostname,
    port: Number(url.port || '6379'),
    username: url.username ? decodeURIComponent(url.username) : undefined,
    password: url.password ? decodeURIComponent(url.password) : undefined,
    tls: url.protocol === 'rediss:' ? {} : undefined,
    maxRetriesPerRequest: null,
  };
}
