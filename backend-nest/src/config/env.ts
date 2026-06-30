import 'dotenv/config';
import { z } from 'zod';

// Centralised, validated environment. Most service keys are optional so the API can boot
// (and serve /health) before every managed service is wired — health reports what's missing.
const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),
  CORS_ORIGIN: z.string().default('*'),

  // Supabase Postgres. Placeholder default lets the app construct PrismaClient before the real
  // Supabase project exists; /health will report db: "down" until DATABASE_URL is set for real.
  DATABASE_URL: z
    .string()
    .default('postgresql://placeholder:placeholder@localhost:5432/placeholder'),
  DIRECT_URL: z.string().optional(),
  SUPABASE_URL: z.string().optional(),
  SUPABASE_ANON_KEY: z.string().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SUPABASE_JWT_SECRET: z.string().optional(),

  // Upstash Redis (rediss://). Empty = disabled until P0 Redis task wires it.
  REDIS_URL: z.string().optional(),

  // AI / Speech
  ANTHROPIC_API_KEY: z.string().optional(),
  AZURE_SPEECH_KEY: z.string().optional(),
  AZURE_SPEECH_REGION: z.string().optional(),
  ELEVENLABS_API_KEY: z.string().optional(),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
export type Env = typeof env;
