// Preset AI tutors the learner can choose from. ALL presets are shown to every user
// (no gender filtering) — the learner picks whoever they like. Voice ids are wired in P2.

export type Pace = 'SLOW' | 'NATURAL' | 'FAST';
export type Accent = 'US' | 'UK';

export interface TutorPreset {
  key: string;
  name: string;
  gender: 'MALE' | 'FEMALE';
  taglineHe: string;
  persona: string; // English snippet injected into the tutor prompt
  pace: Pace;
  accent: Accent;
  voiceId?: string; // set in P2 (ElevenLabs)
}

export const TUTOR_PRESETS: TutorPreset[] = [
  {
    key: 'maya',
    name: 'Maya',
    gender: 'FEMALE',
    taglineHe: 'חמה וסבלנית · מדברת לאט וברור',
    persona:
      'Warm, patient and encouraging. Speaks slowly and very clearly with simple words. Perfect for building confidence.',
    pace: 'SLOW',
    accent: 'US',
  },
  {
    key: 'noa',
    name: 'Noa',
    gender: 'FEMALE',
    taglineHe: 'שמחה ומעודדת · קצב טבעי',
    persona:
      'Cheerful, upbeat and highly encouraging. Celebrates small wins with genuine energy. Natural conversational pace.',
    pace: 'NATURAL',
    accent: 'US',
  },
  {
    key: 'emily',
    name: 'Emily',
    gender: 'FEMALE',
    taglineHe: 'רגועה ואלגנטית · מבטא בריטי',
    persona:
      'Calm, elegant and articulate with a British accent. Polished, gentle and precise in her explanations.',
    pace: 'NATURAL',
    accent: 'UK',
  },
  {
    key: 'ethan',
    name: 'Ethan',
    gender: 'MALE',
    taglineHe: 'סחבק וחברי · קצת יותר מהיר',
    persona:
      'A casual, friendly buddy. Uses natural everyday slang, keeps it light, and speaks a bit faster like a real friend.',
    pace: 'FAST',
    accent: 'US',
  },
  {
    key: 'daniel',
    name: 'Daniel',
    gender: 'MALE',
    taglineHe: 'רגוע ומקצועי · אנגלית לעבודה',
    persona:
      'Calm, professional and clear. Focuses on practical work and business English, polite and well-structured.',
    pace: 'NATURAL',
    accent: 'US',
  },
  {
    key: 'jack',
    name: 'Jack',
    gender: 'MALE',
    taglineHe: 'שנון וכיפי · מבטא בריטי',
    persona:
      'Witty and fun with a British accent. Uses light humour to keep sessions enjoyable while still teaching well.',
    pace: 'NATURAL',
    accent: 'UK',
  },
];

export function findPreset(key: string): TutorPreset | undefined {
  return TUTOR_PRESETS.find((p) => p.key === key);
}

/** Public shape for the client (no internal prompt text needed on the client). */
export function publicPresets() {
  return TUTOR_PRESETS.map((p) => ({
    key: p.key,
    name: p.name,
    gender: p.gender,
    taglineHe: p.taglineHe,
    pace: p.pace,
    accent: p.accent,
  }));
}
