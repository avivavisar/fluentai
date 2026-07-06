import { spawn } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { writeFile, unlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import * as sdk from 'microsoft-cognitiveservices-speech-sdk';
import ffmpegPath from 'ffmpeg-static';
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

  /**
   * Transcribe recorded audio (base64). The browser now records with MediaRecorder,
   * which yields a compressed container (mp4/aac on iOS, webm/opus on Chrome). We decode
   * it to 16 kHz mono 16-bit PCM with ffmpeg, then run Azure STT. This is far more reliable
   * on iOS Safari than the old WebAudio ScriptProcessor PCM capture (which recorded silence).
   */
  async transcribe(audioBase64: string): Promise<string> {
    if (!this.available()) {
      throw new ServiceUnavailableException('Azure Speech is not configured.');
    }
    const input = Buffer.from(audioBase64, 'base64');
    if (input.length < 128) return ''; // nothing recorded
    const pcm = await this.decodeToPcm16k(input);
    if (pcm.length < 640) return ''; // < ~20ms of audio -> treat as silence
    return this.recognizePcm(pcm);
  }

  /** Decode any browser-recorded container to raw 16 kHz mono 16-bit little-endian PCM. */
  private async decodeToPcm16k(input: Buffer): Promise<Buffer> {
    if (!ffmpegPath) throw new ServiceUnavailableException('Audio decoder (ffmpeg) unavailable.');
    // Temp file for input so ffmpeg can seek (mp4 moov atom may sit at the end).
    const inPath = join(tmpdir(), `stt-${randomBytes(8).toString('hex')}`);
    await writeFile(inPath, input);
    try {
      return await new Promise<Buffer>((resolve, reject) => {
        const args = ['-hide_banner', '-loglevel', 'error', '-i', inPath, '-ac', '1', '-ar', '16000', '-f', 's16le', 'pipe:1'];
        const ff = spawn(ffmpegPath as string, args);
        const out: Buffer[] = [];
        let errText = '';
        ff.stdout.on('data', (d: Buffer) => out.push(d));
        ff.stderr.on('data', (d: Buffer) => (errText += d.toString()));
        ff.on('error', reject);
        ff.on('close', (code) => {
          if (code === 0) resolve(Buffer.concat(out));
          else reject(new Error(`ffmpeg exited ${code}: ${errText.slice(0, 300)}`));
        });
      });
    } finally {
      void unlink(inPath).catch(() => {});
    }
  }

  /** Run Azure STT over raw 16 kHz mono 16-bit PCM. */
  private recognizePcm(buf: Buffer): Promise<string> {
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
