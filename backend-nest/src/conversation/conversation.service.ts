import { Injectable, NotFoundException } from '@nestjs/common';
import { Conversation } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import { AiService } from '../ai/ai.service';
import { CreateConversationDto } from './dto/create-conversation.dto';

@Injectable()
export class ConversationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ai: AiService,
  ) {}

  async list(userId: string) {
    const convs = await this.prisma.conversation.findMany({
      where: { userId },
      orderBy: { startedAt: 'desc' },
      take: 30,
      include: {
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        _count: { select: { messages: true } },
      },
    });
    return {
      conversations: convs.map((c) => ({
        id: c.id,
        scenario: c.scenario,
        startedAt: c.startedAt,
        endedAt: c.endedAt,
        messageCount: c._count.messages,
        lastMessage: c.messages[0]?.content ?? null,
      })),
    };
  }

  async create(userId: string, dto: CreateConversationDto) {
    const profile = await this.prisma.profile.findUnique({ where: { userId } });
    const conv = await this.prisma.conversation.create({
      data: {
        userId,
        scenario: dto.scenario ?? 'FREE',
        mode: dto.mode ?? 'text',
        cefrAtStart: profile?.cefrLevel ?? null,
      },
    });
    return { conversation: { id: conv.id, scenario: conv.scenario, mode: conv.mode, startedAt: conv.startedAt } };
  }

  async getMessages(userId: string, conversationId: string) {
    await this.ownedConversation(userId, conversationId);
    const messages = await this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      include: { corrections: true },
    });
    return { messages };
  }

  async postMessage(userId: string, conversationId: string, text: string) {
    const conv = await this.ownedConversation(userId, conversationId);
    const profile = await this.prisma.profile.findUnique({ where: { userId } });

    // Persist the learner's turn first.
    const userMsg = await this.prisma.message.create({
      data: { conversationId, role: 'USER', content: text },
    });

    // History = everything before this new turn.
    const prior = await this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });
    const history = prior
      .filter((m) => m.id !== userMsg.id)
      .map((m) => ({
        role: m.role === 'USER' ? ('user' as const) : ('assistant' as const),
        content: m.content,
      }));

    const result = await this.ai.chatTurn({
      profile: {
        displayName: profile?.displayName,
        cefrLevel: profile?.cefrLevel ?? null,
        goal: profile?.goal ?? 'CASUAL',
        interests: profile?.interests ?? [],
        hebrewSupportLevel: profile?.hebrewSupportLevel ?? 'HEAVY',
      },
      history,
      userMessage: text,
      scenario: conv.scenario,
    });

    // Tutor's reply.
    const assistantMsg = await this.prisma.message.create({
      data: {
        conversationId,
        role: 'ASSISTANT',
        content: result.reply,
        cefrTarget: result.cefr_estimate,
      },
    });

    // Corrections describe the learner's message → link them to the USER message.
    if (result.corrections.length > 0) {
      await this.prisma.correction.createMany({
        data: result.corrections.map((c) => ({
          messageId: userMsg.id,
          type: c.type,
          original: c.original,
          suggestion: c.suggestion,
          explanationEn: c.explanation_en,
          explanationHe: c.explanation_he,
          severity: c.severity,
        })),
      });
    }

    // New vocabulary (deduped per user by term).
    for (const v of result.new_vocab) {
      const exists = await this.prisma.vocabItem.findFirst({ where: { userId, term: v.term } });
      if (!exists) {
        await this.prisma.vocabItem.create({
          data: {
            userId,
            term: v.term,
            definitionEn: v.definition_en,
            definitionHe: v.definition_he,
            example: v.example,
            sourceMessageId: assistantMsg.id,
          },
        });
      }
    }

    return {
      reply: result.reply,
      corrections: result.corrections,
      newVocab: result.new_vocab,
      cefrEstimate: result.cefr_estimate,
      hebrewSupportUsed: result.hebrew_support_used,
      coaching: result.coaching,
      messageId: assistantMsg.id,
      userMessageId: userMsg.id,
    };
  }

  async end(userId: string, conversationId: string) {
    await this.ownedConversation(userId, conversationId);
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { endedAt: new Date() },
    });
    return { ok: true };
  }

  private async ownedConversation(userId: string, id: string): Promise<Conversation> {
    const conv = await this.prisma.conversation.findFirst({ where: { id, userId } });
    if (!conv) throw new NotFoundException('Conversation not found');
    return conv;
  }
}
