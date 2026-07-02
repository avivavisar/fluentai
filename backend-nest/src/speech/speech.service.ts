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

  /** Transcribe base64 16 kHz mono 16-bit PCM audio (from the browser recorder) via Azure STT. */
  transcribe(pcmBase64: string): Promise<string> {
    if (!this.available()) {
      throw new ServiceUnavailableException('Azure Speech is not configured.');
    }
    const buf = Buffer.from(pcmBase64, 'base64');
    const format = sdk.AudioStreamFormat.getWaveFormatPCM(16000, 16, 1);
    const pushStream = sdk.AudioInputStream.createPushStream(format);
    pushStream.write(buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength) as ArrayBuffer);
    pushStream.close();

    const speechConfig = sdk.SpeechConfig.fromSubscription(env.AZURE_SPEECH_KEY!, env.AZURE_SPEECH_REGION!);
    speechConfig.speechRecognitionLanguage = 'en-US';
    const audioConfig = sdk.AudioConfig.fromStreamInput(pushStream);
    const recognizer = new sdk.SpeechRecognizer(speechConfig, audioConfig);

    return new Promise<string>((resolve, reject) => {
      recognizer.recognizeOnceAsync(
        (result) => {
          recognizer.close();
          resolve(result.reason === sdk.ResultReason.RecognizedSpeech ? result.text : '');
        },
        (err) => {
          recognizer.close();
          reject(new Error(typeof err === 'string' ? err : 'STT error'));
        },
      );
    });
  }
}
