import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { synthesizeSpeech, speechAvailable } from '../services/speech.service';

const ttsSchema = z.object({
  text: z.string().min(1).max(2000),
  voice: z.string().optional(),
});

export default async function speechRoutes(app: FastifyInstance) {
  // Text-to-speech: returns MP3 audio for the tutor's reply / "say it like a native".
  app.post('/v1/speech/tts', { preHandler: app.authenticate }, async (req, reply) => {
    if (!speechAvailable()) {
      return reply.code(503).send({ error: { message: 'Speech is not configured.' } });
    }
    const { text, voice } = ttsSchema.parse(req.body);
    const audio = await synthesizeSpeech(text, voice);
    reply.header('Content-Type', 'audio/mpeg');
    reply.header('Cache-Control', 'no-store');
    return reply.send(audio);
  });

  app.get('/v1/speech/status', { preHandler: app.authenticate }, async () => {
    return { available: speechAvailable() };
  });
}
