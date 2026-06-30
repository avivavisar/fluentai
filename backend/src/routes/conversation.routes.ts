import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db';
import { chatTurn } from '../services/anthropic.service';

const startSchema = z.object({
  scenario: z.enum(['FREE', 'TRAVEL', 'BUSINESS', 'INTERVIEW', 'STORY', 'ROLEPLAY']).default('FREE'),
  mode: z.enum(['text', 'voice']).default('text'),
});

const messageSchema = z.object({ text: z.string().min(1) });

export default async function conversationRoutes(app: FastifyInstance) {
  app.get('/v1/conversations', { preHandler: app.authenticate }, async (req) => {
    const convs = await prisma.conversation.findMany({
      where: { userId: req.user.userId },
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
  });

  app.post('/v1/conversations', { preHandler: app.authenticate }, async (req) => {
    const body = startSchema.parse(req.body ?? {});
    const profile = await prisma.profile.findUnique({ where: { userId: req.user.userId } });
    const conv = await prisma.conversation.create({
      data: {
        userId: req.user.userId,
        scenario: body.scenario as never,
        mode: body.mode,
        cefrAtStart: (profile?.cefrLevel ?? null) as never,
      },
    });
    return {
      conversation: { id: conv.id, scenario: conv.scenario, mode: conv.mode, startedAt: conv.startedAt },
    };
  });

  app.get('/v1/conversations/:id/messages', { preHandler: app.authenticate }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const conv = await prisma.conversation.findFirst({ where: { id, userId: req.user.userId } });
    if (!conv) return reply.code(404).send({ error: { message: 'Conversation not found' } });
    const messages = await prisma.message.findMany({
      where: { conversationId: id },
      orderBy: { createdAt: 'asc' },
      include: { corrections: true },
    });
    return { messages };
  });

  app.post('/v1/conversations/:id/messages', { preHandler: app.authenticate }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = messageSchema.parse(req.body);

    const conv = await prisma.conversation.findFirst({ where: { id, userId: req.user.userId } });
    if (!conv) return reply.code(404).send({ error: { message: 'Conversation not found' } });

    const profile = await prisma.profile.findUnique({ where: { userId: req.user.userId } });

    const userMsg = await prisma.message.create({
      data: { conversationId: id, role: 'USER', content: body.text },
    });

    const prior = await prisma.message.findMany({
      where: { conversationId: id },
      orderBy: { createdAt: 'asc' },
    });
    const history = prior
      .filter((m) => m.id !== userMsg.id)
      .map((m) => ({ role: m.role === 'USER' ? ('user' as const) : ('assistant' as const), content: m.content }));

    const result = await chatTurn({
      profile: {
        displayName: profile?.displayName,
        cefrLevel: (profile?.cefrLevel ?? null) as never,
        goal: profile?.goal ?? 'CASUAL',
        interests: profile?.interests ?? [],
        hebrewSupportLevel: (profile?.hebrewSupportLevel ?? 'HEAVY') as never,
      },
      history,
      userMessage: body.text,
      scenario: conv.scenario,
    });

    const assistantMsg = await prisma.message.create({
      data: {
        conversationId: id,
        role: 'ASSISTANT',
        content: result.reply,
        cefrTarget: result.cefr_estimate as never,
        corrections: {
          create: result.corrections.map((c) => ({
            type: c.type as never,
            original: c.original,
            suggestion: c.suggestion,
            explanationEn: c.explanation_en,
            explanationHe: c.explanation_he,
            severity: c.severity as never,
          })),
        },
      },
      include: { corrections: true },
    });

    for (const v of result.new_vocab) {
      const exists = await prisma.vocabItem.findFirst({
        where: { userId: req.user.userId, term: v.term },
      });
      if (!exists) {
        await prisma.vocabItem.create({
          data: {
            userId: req.user.userId,
            term: v.term,
            definitionEn: v.definition_en,
            definitionHe: v.definition_he,
            example: v.example,
            sourceMessageId: assistantMsg.id,
          },
        });
      }
    }

    return reply.send({
      reply: result.reply,
      corrections: assistantMsg.corrections,
      newVocab: result.new_vocab,
      cefrEstimate: result.cefr_estimate,
      hebrewSupportUsed: result.hebrew_support_used,
      coaching: result.coaching,
      messageId: assistantMsg.id,
    });
  });

  app.post('/v1/conversations/:id/end', { preHandler: app.authenticate }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const conv = await prisma.conversation.findFirst({ where: { id, userId: req.user.userId } });
    if (!conv) return reply.code(404).send({ error: { message: 'Conversation not found' } });
    await prisma.conversation.update({ where: { id }, data: { endedAt: new Date() } });
    return { ok: true };
  });
}
