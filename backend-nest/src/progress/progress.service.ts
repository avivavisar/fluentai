import { Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';

@Injectable()
export class ProgressService {
  constructor(private readonly prisma: PrismaService) {}

  async getProgress(userId: string) {
    const [profile, gamification, wordsLearned, conversationsCount, recent] = await Promise.all([
      this.prisma.profile.findUnique({ where: { userId } }),
      this.prisma.gamification.findUnique({ where: { userId } }),
      this.prisma.vocabItem.count({ where: { userId } }),
      this.prisma.conversation.count({ where: { userId } }),
      this.prisma.conversation.findMany({
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
  }
}
