import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { translateToHebrew } from '../services/anthropic.service';

const schema = z.object({ text: z.string().min(1) });

export default async function translateRoutes(app: FastifyInstance) {
  app.post('/v1/translate', { preHandler: app.authenticate }, async (req) => {
    const { text } = schema.parse(req.body);
    const hebrew = await translateToHebrew(text);
    return { hebrew };
  });
}
