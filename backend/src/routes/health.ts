import { FastifyInstance } from 'fastify';
import { prisma } from '../db';
import { redis, redisEnabled } from '../redis';

export default async function healthRoutes(app: FastifyInstance) {
  app.get('/health', async () => {
    const result: { status: string; db: string; redis: string } = {
      status: 'ok',
      db: 'unknown',
      redis: 'unknown',
    };

    try {
      await prisma.$queryRaw`SELECT 1`;
      result.db = 'up';
    } catch {
      result.db = 'down';
      result.status = 'degraded';
    }

    if (!redisEnabled || !redis) {
      result.redis = 'disabled';
    } else {
      try {
        const pong = await redis.ping();
        result.redis = pong === 'PONG' ? 'up' : 'down';
        if (result.redis === 'down') result.status = 'degraded';
      } catch {
        result.redis = 'down';
        result.status = 'degraded';
      }
    }

    return result;
  });
}
