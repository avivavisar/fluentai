import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db';
import {
  PLACEMENT_QUESTIONS,
  WRITING_PROMPT,
  WRITING_PROMPT_HE,
  publicQuestions,
} from '../data/placementQuestions';
import { gradePlacement } from '../services/anthropic.service';
import { suggestSupportLevel, isCefr } from '../services/cefr';

const submitSchema = z.object({
  answers: z.array(z.object({ id: z.string(), answer: z.string() })),
  writingSample: z.string().default(''),
});

export default async function placementRoutes(app: FastifyInstance) {
  app.get('/v1/placement/questions', { preHandler: app.authenticate }, async () => {
    return {
      questions: publicQuestions(),
      writingPrompt: WRITING_PROMPT,
      writingPromptHe: WRITING_PROMPT_HE,
    };
  });

  app.post('/v1/placement/submit', { preHandler: app.authenticate }, async (req) => {
    const body = submitSchema.parse(req.body);

    const graded = body.answers
      .map((a) => {
        const q = PLACEMENT_QUESTIONS.find((x) => x.id === a.id);
        if (!q) return null;
        const correct = q.options[q.answerIndex];
        return {
          id: q.id,
          level: q.level,
          prompt: q.prompt,
          promptHe: q.promptHe,
          explanationHe: q.explanationHe,
          chosen: a.answer,
          correct,
          isCorrect: a.answer === correct,
        };
      })
      .filter((x): x is NonNullable<typeof x> => x !== null);

    const grade = await gradePlacement({
      answers: graded,
      writingPrompt: WRITING_PROMPT,
      writingSample: body.writingSample,
    });

    const cefr = isCefr(grade.cefr_level) ? grade.cefr_level : 'A2';
    const support = suggestSupportLevel(cefr);

    await prisma.placementTest.create({
      data: {
        userId: req.user.userId,
        answers: body as unknown as object,
        resultCefr: cefr as never,
        confidence: grade.confidence,
        rationale: grade.rationale,
      },
    });

    const profile = await prisma.profile.update({
      where: { userId: req.user.userId },
      data: {
        cefrLevel: cefr as never,
        cefrConfidence: grade.confidence,
        hebrewSupportLevel: support as never,
      },
    });

    return {
      result: {
        cefrLevel: cefr,
        confidence: grade.confidence,
        rationale: grade.rationale,
        suggestedSupport: support,
      },
      review: graded.map((g) => ({
        prompt: g.prompt,
        promptHe: g.promptHe,
        explanationHe: g.explanationHe,
        chosen: g.chosen,
        correct: g.correct,
        isCorrect: g.isCorrect,
      })),
      profile,
    };
  });
}
