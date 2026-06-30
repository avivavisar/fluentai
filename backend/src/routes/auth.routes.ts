import { FastifyInstance } from 'fastify';
import { Prisma } from '@prisma/client';
import { prisma } from '../db';
import { hashPassword, verifyPassword } from '../utils/password';
import { signupSchema, loginSchema } from '../schemas/auth.schema';

type UserWithProfile = Prisma.UserGetPayload<{ include: { profile: true } }>;

function publicUser(user: UserWithProfile) {
  return {
    id: user.id,
    email: user.email,
    uiLanguage: user.uiLanguage,
    profile: user.profile && {
      displayName: user.profile.displayName,
      cefrLevel: user.profile.cefrLevel,
      goal: user.profile.goal,
      interests: user.profile.interests,
      hebrewSupportLevel: user.profile.hebrewSupportLevel,
      voiceEnabled: user.profile.voiceEnabled,
      onboardingComplete: user.profile.onboardingComplete,
    },
  };
}

export default async function authRoutes(app: FastifyInstance) {
  app.post('/v1/auth/signup', async (req, reply) => {
    const body = signupSchema.parse(req.body);

    const existing = await prisma.user.findUnique({ where: { email: body.email } });
    if (existing) {
      return reply.code(409).send({ error: { message: 'Email already registered' } });
    }

    const passwordHash = await hashPassword(body.password);
    const user = await prisma.user.create({
      data: {
        email: body.email,
        passwordHash,
        profile: { create: { displayName: body.displayName } },
        gamification: { create: {} },
      },
      include: { profile: true },
    });

    const token = app.jwt.sign({ userId: user.id });
    return reply.code(201).send({ token, user: publicUser(user) });
  });

  app.post('/v1/auth/login', async (req, reply) => {
    const body = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: body.email },
      include: { profile: true },
    });
    if (!user || !(await verifyPassword(body.password, user.passwordHash))) {
      return reply.code(401).send({ error: { message: 'Invalid email or password' } });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { lastActiveAt: new Date() },
    });

    const token = app.jwt.sign({ userId: user.id });
    return { token, user: publicUser(user) };
  });

  app.post('/v1/auth/refresh', { preHandler: app.authenticate }, async (req) => {
    const token = app.jwt.sign({ userId: req.user.userId });
    return { token };
  });
}
