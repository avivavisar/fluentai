import { Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { AiService } from '../ai/ai.service';
import { isCefr, suggestSupportLevel } from '../ai/cefr';
import {
  PLACEMENT_QUESTIONS,
  WRITING_PROMPT,
  WRITING_PROMPT_HE,
  publicQuestions,
} from './placement-questions';
import { SubmitPlacementDto } from './dto/submit-placement.dto';

@Injectable()
export class PlacementService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ai: AiService,
  ) {}

  getQuestions() {
    return {
      questions: publicQuestions(),
      writingPrompt: WRITING_PROMPT,
      writingPromptHe: WRITING_PROMPT_HE,
    };
  }

  async submit(userId: string, dto: SubmitPlacementDto) {
    // Grade MC answers server-side against the bank (client never saw the correct answers).
    const graded = dto.answers
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

    const grade = await this.ai.gradePlacement({
      answers: graded,
      writingPrompt: WRITING_PROMPT,
      writingSample: dto.writingSample ?? '',
    });

    const cefr = isCefr(grade.cefr_level) ? grade.cefr_level : 'A2';
    const support = suggestSupportLevel(cefr);

    await this.prisma.placementTest.create({
      data: {
        userId,
        answers: dto as unknown as object,
        resultCefr: cefr,
        confidence: grade.confidence,
        rationale: grade.rationale,
      },
    });

    const profile = await this.prisma.profile.upsert({
      where: { userId },
      create: { userId, cefrLevel: cefr, cefrConfidence: grade.confidence, hebrewSupportLevel: support },
      update: { cefrLevel: cefr, cefrConfidence: grade.confidence, hebrewSupportLevel: support },
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
  }
}
