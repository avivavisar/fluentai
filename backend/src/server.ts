import { buildApp } from './app';
import { config } from './config';
import { connectDb, disconnectDb } from './db';
import { connectRedis, redis } from './redis';

async function main() {
  const app = buildApp();

  await connectDb();
  if (redis) {
    try {
      await connectRedis();
    } catch {
      app.log.warn('Redis not reachable at startup; will retry on first use.');
    }
  }

  await app.listen({ port: config.PORT, host: config.HOST });

  const shutdown = async () => {
    app.log.info('Shutting down...');
    await app.close();
    await disconnectDb();
    redis?.disconnect();
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
