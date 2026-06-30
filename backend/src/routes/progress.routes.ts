import { FastifyInstance } from 'fastify';
import { prisma } from '../db';

export default async function progressRoutes(app: FastifyInstance) {
  app.get('/v1/progress', { preHandler: app.authenticate }, async (req) => {
    const userId = req.user.userId;
    const [profile, gamification, wordsLearned, conversationsCount, recent] = await Promise.all([
      prisma.profile.findUnique({ where: { userId } }),
      prisma.gamification.findUnique({ where: { userId } }),
      prisma.vocabItem.count({ where: { userId } }),
      prisma.conversation.count({ where: { userId } }),
      prisma.conversation.findMany({
        where: { userId },
        orderBy: { startedAt: 'desc' },
        take: 5,
        select: { id: true, scenario: true, startedAt: true, endedAt: true },
      }),
    ]);

    return {
      cefrLevel: profile?.cefrLevel ?? null,
      cefrConfidence: profile?.cefrConfidence ?? 0,
      xp: gamification?.xpTotal ?? 0,
      level: gamification?.level ?? 1,
      streak: gamification?.currentStreak ?? 0,
      wordsLearned,
      conversationsCount,
      recentConversations: recent,
    };
  });

  app.get('/v1/vocab', { preHandler: app.authenticate }, async (req) => {
    const items = await prisma.vocabItem.findMany({
      where: { userId: req.user.userId },
      orderBy: { createdAt: 'desc' },
    });
    return { items };
  });
}
