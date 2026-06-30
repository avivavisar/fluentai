// Adaptive-ish placement bank: multiple-choice items of increasing difficulty, plus one open
// writing prompt. Each item has a Hebrew translation (promptHe) + short Hebrew explanation so
// absolute beginners can understand and learn. `answerIndex` is server-side only (never sent to client).

export interface PlacementQuestion {
  id: string;
  level: 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2';
  prompt: string;
  promptHe: string;
  options: string[];
  answerIndex: number;
  explanationHe: string;
}

export const PLACEMENT_QUESTIONS: PlacementQuestion[] = [
  {
    id: 'q1', level: 'A1', prompt: 'She ___ a student.',
    promptHe: 'היא ___ תלמידה.', options: ['is', 'are', 'am', 'be'], answerIndex: 0,
    explanationHe: 'עם he/she/it משתמשים ב-is.',
  },
  {
    id: 'q2', level: 'A1', prompt: 'I have two ___.',
    promptHe: 'יש לי שני ___ (ילדים).', options: ['child', 'childs', 'children', 'childes'], answerIndex: 2,
    explanationHe: 'צורת הרבים של child היא children (לא childs).',
  },
  {
    id: 'q3', level: 'A2', prompt: 'Yesterday we ___ to the cinema.',
    promptHe: 'אתמול ___ לקולנוע.', options: ['go', 'gone', 'went', 'going'], answerIndex: 2,
    explanationHe: 'צורת העבר של go היא went.',
  },
  {
    id: 'q4', level: 'A2', prompt: 'He is taller ___ his brother.',
    promptHe: 'הוא גבוה ___ אחיו.', options: ['then', 'than', 'that', 'as'], answerIndex: 1,
    explanationHe: 'בהשוואה (יותר מ-) משתמשים ב-than.',
  },
  {
    id: 'q5', level: 'B1', prompt: 'If it rains, we ___ at home.',
    promptHe: 'אם ירד גשם, אנחנו ___ בבית.', options: ['stay', 'will stay', 'stayed', 'would stay'], answerIndex: 1,
    explanationHe: 'במשפט תנאי רגיל: if + הווה, ואז will + פועל.',
  },
  {
    id: 'q6', level: 'B1', prompt: "I've lived here ___ 2015.",
    promptHe: 'אני גר כאן ___ שנת 2015.', options: ['for', 'since', 'from', 'during'], answerIndex: 1,
    explanationHe: 'עם נקודת זמן מסוימת (2015) משתמשים ב-since. עם משך זמן משתמשים ב-for.',
  },
  {
    id: 'q7', level: 'B2', prompt: 'By the time we arrived, the film ___.',
    promptHe: 'עד שהגענו, הסרט ___ (כבר התחיל).',
    options: ['already started', 'had already started', 'has already started', 'was already starting'], answerIndex: 1,
    explanationHe: 'פעולה שהסתיימה לפני פעולה אחרת בעבר דורשת past perfect: had started.',
  },
  {
    id: 'q8', level: 'B2', prompt: 'She suggested ___ a break.',
    promptHe: 'היא הציעה ___ הפסקה.', options: ['to take', 'taking', 'take', 'we taking'], answerIndex: 1,
    explanationHe: 'אחרי הפועל suggest משתמשים בצורת ה-ing (taking).',
  },
  {
    id: 'q9', level: 'C1', prompt: 'Not until much later ___ the truth.',
    promptHe: 'רק הרבה יותר מאוחר ___ את האמת.',
    options: ['I realised', 'did I realise', 'I did realise', 'realised I'], answerIndex: 1,
    explanationHe: 'כשמשפט נפתח בביטוי שלילי (Not until) יש היפוך נושא-עזר: did I realise.',
  },
  {
    id: 'q10', level: 'C1', prompt: 'The proposal was, ___ all intents and purposes, rejected.',
    promptHe: 'ההצעה, ___ כל מטרה מעשית, נדחתה.', options: ['to', 'for', 'by', 'at'], answerIndex: 1,
    explanationHe: 'זהו ביטוי קבוע: "for all intents and purposes" (למעשה).',
  },
];

export const WRITING_PROMPT =
  'In 2–3 sentences, describe what you did last weekend and what you plan to do next weekend.';

export const WRITING_PROMPT_HE =
  'ב-2 עד 3 משפטים, תאר מה עשית בסוף השבוע שעבר ומה אתה מתכנן לעשות בסוף השבוע הבא. (כתוב באנגלית)';

// Public shape (no correct answers leaked to the client).
export function publicQuestions() {
  return PLACEMENT_QUESTIONS.map((q) => ({
    id: q.id,
    level: q.level,
    prompt: q.prompt,
    promptHe: q.promptHe,
    options: q.options,
  }));
}
