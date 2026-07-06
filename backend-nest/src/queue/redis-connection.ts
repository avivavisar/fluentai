import type { RedisOptions } from 'ioredis';
import { env } from '../config/env';

/**
 * Build ioredis options for BullMQ from REDIS_URL (Upstash rediss://).
 * BullMQ requires `maxRetriesPerRequest: null` for its blocking connections,
 * which is why we don't reuse the health-check client (it sets a finite value).
 */
// Benign fallback when REDIS_URL is missing/invalid: BullMQ won't connect (lazy, offline
// queue disabled) so the API still boots and serves — queue features are simply inactive
// instead of crashing the whole process at startup.
const INACTIVE: RedisOptions = {
  host: '127.0.0.1',
  port: 6379,
  maxRetriesPerRequest: null,
  enableOfflineQueue: false,
  lazyConnect: true,
};

export function buildBullConnection(): RedisOptions {
  if (!env.REDIS_URL) return INACTIVE;
  let url: URL;
  try {
    url = new URL(env.REDIS_URL);
  } catch {
    // eslint-disable-next-line no-console
    console.warn('REDIS_URL is not a valid URL — job queue disabled.');
    return INACTIVE;
  }
  return {
    host: url.hostname,
    port: Number(url.port || '6379'),
    username: url.username ? decodeURIComponent(url.username) : undefined,
    password: url.password ? decodeURIComponent(url.password) : undefined,
    tls: url.protocol === 'rediss:' ? {} : undefined,
    maxRetriesPerRequest: null,
  };
}
