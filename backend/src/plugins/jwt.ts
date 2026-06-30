import fp from 'fastify-plugin';
import jwt from '@fastify/jwt';
import { config } from '../config';

// Registers JWT support and an `authenticate` preHandler used to guard routes.
export default fp(async (app) => {
  await app.register(jwt, {
    secret: config.JWT_SECRET,
    sign: { expiresIn: config.JWT_EXPIRES_IN },
  });

  app.decorate('authenticate', async (req, reply) => {
    try {
      await req.jwtVerify();
    } catch {
      reply.code(401).send({ error: { message: 'Unauthorized' } });
    }
  });
});
