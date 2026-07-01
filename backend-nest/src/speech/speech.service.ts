import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import * as sdk from 'microsoft-cognitiveservices-speech-sdk';
import { PrismaService } from '../common/prisma/prisma.service';
import { findPreset } from '../companion/companion-presets';
import { env } from '../config/env';

const DEFAULT_VOICE = 'en-US-JennyNeural';

@Injectable()
export class SpeechService {
  constructor(private readonly prisma: PrismaService) {}

  available(): boolean {
    return !!(env.AZURE_SPEECH_KEY && env.AZURE_SPEECH_REGION);
  }

  /** Synthesize using the learner's chosen tutor voice. */
  async synthesizeForUser(userId: string, text: string): Promise<Buffer> {
    const companion = await this.prisma.companion.findUnique({ where: { userId } });
    const voice = (companion && findPreset(companion.role ?? '')?.voiceId) || DEFAULT_VOICE;
    return this.synthesize(text, voice);
  }

  synthesize(text: string, voice: string): Promise<Buffer> {
    if (!this.available()) {
      throw new ServiceUnavailableException('Azure Speech is not configured.');
    }
    const speechConfig = sdk.SpeechConfig.fromSubscription(env.AZURE_SPEECH_KEY!, env.AZURE_SPEECH_REGION!);
    speechConfig.speechSynthesisVoiceName = voice;
    speechConfig.speechSynthesisOutputFormat = sdk.SpeechSynthesisOutputFormat.Audio24Khz96KBitRateMonoMp3;
    const synthesizer = new sdk.SpeechSynthesizer(speechConfig, null as unknown as sdk.AudioConfig);

    return new Promise<Buffer>((resolve, reject) => {
      synthesizer.speakTextAsync(
        text,
        (result) => {
          synthesizer.close();
          if (result.reason === sdk.ResultReason.SynthesizingAudioCompleted) {
            resolve(Buffer.from(result.audioData));
          } else {
            reject(new Error(result.errorDetails || 'TTS synthesis failed'));
          }
        },
        (err) => {
          synthesizer.close();
          reject(new Error(typeof err === 'string' ? err : 'TTS synthesis error'));
        },
      );
    });
  }
}
