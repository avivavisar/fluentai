import { Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';

@Injectable()
export class VocabService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    const items = await this.prisma.vocabItem.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { srsReview: true },
    });
    return { count: items.length, vocab: items };
  }
}
