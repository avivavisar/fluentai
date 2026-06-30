import Fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import fastifyStatic from '@fastify/static';
import path from 'node:path';
import fs from 'node:fs';
import { ZodError } from 'zod';
import { config } from './config';
import jwtPlugin from './plugins/jwt';
import websocketPlugin from './plugins/websocket';
import healthRoutes from './routes/health';
import authRoutes from './routes/auth.routes';
import profileRoutes from './routes/profile.routes';
import placementRoutes from './routes/placement.routes';
import conversationRoutes from './routes/conversation.routes';
import progressRoutes from './routes/progress.routes';
import translateRoutes from './routes/translate.routes';
import speechRoutes from './routes/speech.routes';

export function buildApp(): FastifyInstance {
  const app = Fastify({
    logger: { level: config.NODE_ENV === 'production' ? 'info' : 'debug' },
  });

  app.register(cors, { origin: config.CORS_ORIGIN });
  app.register(jwtPlugin);
  app.register(websocketPlugin);

  // API routes
  app.register(healthRoutes);
  app.register(authRoutes);
  app.register(profileRoutes);
  app.register(placementRoutes);
  app.register(conversationRoutes);
  app.register(progressRoutes);
  app.register(translateRoutes);
  app.register(speechRoutes);

  // Serve the built Flutter web app from the same origin (for tunnel sharing).
  const webDir = path.resolve(__dirname, '../../frontend/build/web');
  const hasWeb = fs.existsSync(path.join(webDir, 'index.html'));
  if (hasWeb) {
    app.register(fastifyStatic, { root: webDir, prefix: '/' });
  }

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof ZodError) {
      return reply.status(400).send({
        error: { message: 'Validation failed', details: err.flatten().fieldErrors },
      });
    }
    req.log.error(err);
    const status = err.statusCode ?? 500;
    reply.status(status).send({
      error: { message: status === 500 ? 'Internal Server Error' : err.message },
    });
  });

  app.setNotFoundHandler((req, reply) => {
    const url = req.url;
    const isApi =
      url.startsWith('/v1') || url.startsWith('/health') || url.startsWith('/ws');
    if (!isApi && req.method === 'GET' && hasWeb) {
      return reply.sendFile('index.html');
    }
    reply.status(404).send({ error: { message: 'Not Found' } });
  });

  return app;
}
