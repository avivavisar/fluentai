import { z } from 'zod';

export const updateProfileSchema = z.object({
  displayName: z.string().min(1).optional(),
  goal: z.enum(['TRAVEL', 'BUSINESS', 'EXAM', 'CASUAL']).optional(),
  interests: z.array(z.string()).optional(),
  hebrewSupportLevel: z.enum(['NONE', 'LIGHT', 'HEAVY']).optional(),
  voiceEnabled: z.boolean().optional(),
  onboardingComplete: z.boolean().optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
