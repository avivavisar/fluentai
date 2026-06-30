import { FastifyInstance } from 'fastify';
import { prisma } from '../db';
import { updateProfileSchema } from '../schemas/profile.schema';

export default async function profileRoutes(app: FastifyInstance) {
  app.get('/v1/profile', { preHandler: app.authenticate }, async (req, reply) => {
    const profile = await prisma.profile.findUnique({
      where: { userId: req.user.userId },
    });
    if (!profile) {
      return reply.code(404).send({ error: { message: 'Profile not found' } });
    }
    return { profile };
  });

  app.patch('/v1/profile', { preHandler: app.authenticate }, async (req) => {
    const body = updateProfileSchema.parse(req.body);
    const profile = await prisma.profile.update({
      where: { userId: req.user.userId },
      data: body,
    });
    return { profile };
  });
}
