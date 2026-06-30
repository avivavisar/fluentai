export const CEFR_ORDER = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'] as const;
export type Cefr = (typeof CEFR_ORDER)[number];

export function isCefr(value: unknown): value is Cefr {
  return typeof value === 'string' && (CEFR_ORDER as readonly string[]).includes(value);
}

// Suggest how much Hebrew scaffolding to show, based on level.
export function suggestSupportLevel(cefr?: Cefr | null): 'NONE' | 'LIGHT' | 'HEAVY' {
  if (!cefr) return 'HEAVY';
  const i = CEFR_ORDER.indexOf(cefr);
  if (i <= 1) return 'HEAVY'; // A1, A2
  if (i <= 3) return 'LIGHT'; // B1, B2
  return 'NONE'; // C1, C2
}

// One sub-level above the learner (i+1), capped at C2.
export function nextLevel(cefr?: Cefr | null): Cefr {
  if (!cefr) return 'A2';
  const i = CEFR_ORDER.indexOf(cefr);
  return CEFR_ORDER[Math.min(i + 1, CEFR_ORDER.length - 1)];
}
