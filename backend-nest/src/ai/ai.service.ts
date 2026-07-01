import Anthropic from '@anthropic-ai/sdk';
import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { env } from '../config/env';
import { CEFR_ORDER, nextLevel, type Cefr } from './cefr';

const MODEL = 'claude-opus-4-8';
// Translation is a simple task and cost-sensitive — use the cheap tier.
const TRANSLATE_MODEL = 'claude-haiku-4-5';

export interface ChatProfile {
  displayName?: string | null;
  cefrLevel?: Cefr | null;
  goal: string;
  interests: string[];
  hebrewSupportLevel: 'NONE' | 'LIGHT' | 'HEAVY';
}

export interface ChatHistoryItem {
  role: 'user' | 'assistant';
  content: string;
}

export interface CorrectionOut {
  type: 'GRAMMAR' | 'VOCAB' | 'WORD_CHOICE' | 'NATURALNESS';
  original: string;
  suggestion: string;
  explanation_en: string;
  explanation_he: string;
  severity: 'LOW' | 'MEDIUM' | 'HIGH';
}

export interface VocabOut {
  term: string;
  definition_en: string;
  definition_he: string;
  example: string;
}

export interface Coaching {
  fluency_en: string;
  fluency_he: string;
  tone_en: string;
  tone_he: string;
}

export interface ChatTurnResult {
  reply: string;
  corrections: CorrectionOut[];
  new_vocab: VocabOut[];
  cefr_estimate: Cefr;
  hebrew_support_used: boolean;
  coaching: Coaching;
}

export interface PlacementGrade {
  cefr_level: Cefr;
  confidence: number;
  rationale: string;
  writing_feedback: string;
}

const TUTOR_RUBRIC = `You are "FluentAI", a warm, patient English tutor for native HEBREW speakers learning English.

PEDAGOGY (follow strictly):
- Speak almost entirely in natural English. Keep your spoken English at roughly one CEFR sub-level
  above the learner (comprehensible input, i+1). Never overwhelm.
- Be encouraging first, corrective second (keep the learner's anxiety low).
- Each turn, correct AT MOST the 1-3 most valuable mistakes — do not nitpick everything.
- Corrections are gentle recasts, not red-pen. For every correction include BOTH an English
  explanation and a Hebrew explanation.
- Surface up to 2 genuinely new/useful vocabulary items the learner could adopt (with Hebrew gloss).
- In your "reply", when the learner's last message has a correction, FIRST gently and explicitly
  acknowledge it before continuing. For the single most important fix, name it directly, e.g.:
  'Quick note — you wrote "<their words>". The correct way is: "<corrected words>".' Then add a
  short comprehension check like "Does that make sense?". For HEAVY-support learners you MAY add a
  brief 2-4 word Hebrew check in parentheses (e.g. "(הבנת?)"); for LIGHT/NONE keep the reply fully
  in English. After the check, continue the conversation naturally and end with a question.
- If the learner's last message has NO mistakes, praise them briefly and continue with a question.

HEBREW SUPPORT LEVEL controls how much Hebrew the learner needs in explanations:
- HEAVY (beginners): explanations should lean on Hebrew; keep English simple.
- LIGHT: English-first; Hebrew is a short helper.
- NONE: still PROVIDE explanation_he (the app may show it on demand), but keep English immersive.
Never mix Hebrew into the English "reply" itself — Hebrew lives only in the explanation fields.

OUTPUT: respond ONLY as the JSON object defined by the response schema. No prose outside it.
- "reply": your spoken English response to the learner.
- "corrections": fixes to the learner's LAST message (empty array if none needed).
- "new_vocab": optional new words (empty array if none).
- "cefr_estimate": your current estimate of the learner's level (A1..C2).
- "hebrew_support_used": true if you leaned on Hebrew in this turn.
- "coaching": ONE short fluency tip and ONE short tone tip about HOW the learner spoke this turn,
  each in English AND Hebrew, each under ~12 words. If they spoke well, give brief encouraging praise.`;

const CORRECTION_ITEM_SCHEMA = {
  type: 'object',
  properties: {
    type: { type: 'string', enum: ['GRAMMAR', 'VOCAB', 'WORD_CHOICE', 'NATURALNESS'] },
    original: { type: 'string' },
    suggestion: { type: 'string' },
    explanation_en: { type: 'string' },
    explanation_he: { type: 'string' },
    severity: { type: 'string', enum: ['LOW', 'MEDIUM', 'HIGH'] },
  },
  required: ['type', 'original', 'suggestion', 'explanation_en', 'explanation_he', 'severity'],
  additionalProperties: false,
};

const VOCAB_ITEM_SCHEMA = {
  type: 'object',
  properties: {
    term: { type: 'string' },
    definition_en: { type: 'string' },
    definition_he: { type: 'string' },
    example: { type: 'string' },
  },
  required: ['term', 'definition_en', 'definition_he', 'example'],
  additionalProperties: false,
};

const COACHING_SCHEMA = {
  type: 'object',
  properties: {
    fluency_en: { type: 'string' },
    fluency_he: { type: 'string' },
    tone_en: { type: 'string' },
    tone_he: { type: 'string' },
  },
  required: ['fluency_en', 'fluency_he', 'tone_en', 'tone_he'],
  additionalProperties: false,
};

const CHAT_SCHEMA = {
  type: 'object',
  properties: {
    reply: { type: 'string' },
    corrections: { type: 'array', items: CORRECTION_ITEM_SCHEMA },
    new_vocab: { type: 'array', items: VOCAB_ITEM_SCHEMA },
    cefr_estimate: { type: 'string', enum: [...CEFR_ORDER] },
    hebrew_support_used: { type: 'boolean' },
    coaching: COACHING_SCHEMA,
  },
  required: ['reply', 'corrections', 'new_vocab', 'cefr_estimate', 'hebrew_support_used', 'coaching'],
  additionalProperties: false,
};

const PLACEMENT_SCHEMA = {
  type: 'object',
  properties: {
    cefr_level: { type: 'string', enum: [...CEFR_ORDER] },
    confidence: { type: 'number' },
    rationale: { type: 'string' },
    writing_feedback: { type: 'string' },
  },
  required: ['cefr_level', 'confidence', 'rationale', 'writing_feedback'],
  additionalProperties: false,
};

@Injectable()
export class AiService {
  private readonly client: Anthropic | null = env.ANTHROPIC_API_KEY
    ? new Anthropic({ apiKey: env.ANTHROPIC_API_KEY })
    : null;

  available(): boolean {
    return this.client !== null;
  }

  private requireClient(): Anthropic {
    if (!this.client) {
      throw new ServiceUnavailableException(
        'AI is not configured. Set ANTHROPIC_API_KEY in the backend environment.',
      );
    }
    return this.client;
  }

  private firstJson<T>(content: Anthropic.Messages.ContentBlock[]): T {
    const textBlock = content.find((b) => b.type === 'text') as
      | Anthropic.Messages.TextBlock
      | undefined;
    if (!textBlock) throw new Error('No text content in model response');
    return JSON.parse(textBlock.text) as T;
  }

  // ---------- Chat teacher ----------
  async chatTurn(params: {
    profile: ChatProfile;
    history: ChatHistoryItem[];
    userMessage: string;
    scenario?: string;
  }): Promise<ChatTurnResult> {
    const client = this.requireClient();
    const { profile, history, userMessage, scenario } = params;
    const target = nextLevel(profile.cefrLevel ?? null);

    const profileBlock = [
      `LEARNER PROFILE:`,
      `- name: ${profile.displayName ?? 'the learner'}`,
      `- current level (CEFR): ${profile.cefrLevel ?? 'unknown (assume A2)'}`,
      `- speak at about: ${target}`,
      `- goal: ${profile.goal}`,
      `- interests: ${profile.interests.join(', ') || 'unknown'}`,
      `- hebrew support level: ${profile.hebrewSupportLevel}`,
      scenario && scenario !== 'FREE'
        ? `- scenario/roleplay: ${scenario}`
        : `- mode: free conversation`,
    ].join('\n');

    // Cap history to keep token usage in check.
    const recent = history.slice(-12);

    const resp = await client.messages.create({
      model: MODEL,
      max_tokens: 2000,
      thinking: { type: 'adaptive' },
      system: [
        { type: 'text', text: TUTOR_RUBRIC, cache_control: { type: 'ephemeral' } },
        { type: 'text', text: profileBlock },
      ],
      output_config: { format: { type: 'json_schema', schema: CHAT_SCHEMA } },
      messages: [
        ...recent.map((m) => ({ role: m.role, content: m.content })),
        { role: 'user' as const, content: userMessage },
      ],
    } as Anthropic.Messages.MessageCreateParamsNonStreaming);

    return this.firstJson<ChatTurnResult>(resp.content);
  }

  // ---------- Placement grading ----------
  async gradePlacement(params: {
    answers: {
      id: string;
      level: string;
      prompt: string;
      chosen: string;
      correct: string;
      isCorrect: boolean;
    }[];
    writingPrompt: string;
    writingSample: string;
  }): Promise<PlacementGrade> {
    const client = this.requireClient();

    const mcSummary = params.answers
      .map(
        (a) =>
          `[${a.level}] "${a.prompt}" chose: "${a.chosen}" (${
            a.isCorrect ? 'correct' : `wrong, answer: "${a.correct}"`
          })`,
      )
      .join('\n');

    const userContent = [
      'Assess this English learner (native Hebrew speaker) and assign a CEFR level (A1..C2).',
      '',
      'MULTIPLE-CHOICE RESULTS (by difficulty):',
      mcSummary,
      '',
      `WRITING PROMPT: ${params.writingPrompt}`,
      `LEARNER WROTE: "${params.writingSample || '(left blank)'}"`,
      '',
      'Weigh both the multiple-choice accuracy across difficulty levels AND the writing sample',
      '(range of grammar, vocabulary, accuracy, coherence). Return your best single CEFR level,',
      'a confidence between 0 and 1, and a one-sentence rationale.',
      '',
      'ALSO return "writing_feedback": a warm, empathetic message IN HEBREW (2-4 sentences) to the learner',
      'about THEIR WRITING SAMPLE specifically. Structure it kindly, like a caring teacher:',
      '1) first genuinely praise something concrete they did well in their writing;',
      '2) if there are mistakes, gently point out 1-2 of them and show the correction (quote the English);',
      '3) reassure them warmly that they are in exactly the right place and will improve together with you.',
      'Be encouraging, personal and kind — never harsh or discouraging. Speak as "מאיה" the tutor.',
      "If the writing was left blank, warmly say that's completely fine and you'll practice writing together.",
    ].join('\n');

    const resp = await client.messages.create({
      model: MODEL,
      max_tokens: 800,
      thinking: { type: 'adaptive' },
      system: [
        {
          type: 'text',
          text: 'You are a precise CEFR placement examiner for English. Be calibrated, not generous.',
        },
      ],
      output_config: { format: { type: 'json_schema', schema: PLACEMENT_SCHEMA } },
      messages: [{ role: 'user', content: userContent }],
    } as Anthropic.Messages.MessageCreateParamsNonStreaming);

    return this.firstJson<PlacementGrade>(resp.content);
  }

  // ---------- Quick translation (English -> Hebrew) ----------
  async translateToHebrew(text: string): Promise<string> {
    const client = this.requireClient();
    const resp = await client.messages.create({
      model: TRANSLATE_MODEL,
      max_tokens: 600,
      system:
        "Translate the user's English text into natural, fluent Hebrew. Output ONLY the Hebrew translation — no quotes, no notes.",
      messages: [{ role: 'user', content: text }],
    } as Anthropic.Messages.MessageCreateParamsNonStreaming);
    const block = resp.content.find((b) => b.type === 'text') as
      | Anthropic.Messages.TextBlock
      | undefined;
    return block?.text?.trim() ?? '';
  }
}
