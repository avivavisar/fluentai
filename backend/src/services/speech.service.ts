import * as sdk from 'microsoft-cognitiveservices-speech-sdk';
import { config } from '../config';

export function speechAvailable(): boolean {
  return Boolean(config.AZURE_SPEECH_KEY && config.AZURE_SPEECH_REGION);
}

function buildSpeechConfig(): sdk.SpeechConfig {
  return sdk.SpeechConfig.fromSubscription(
    config.AZURE_SPEECH_KEY as string,
    config.AZURE_SPEECH_REGION as string,
  );
}

// Default neural voices.
export const DEFAULT_VOICE = 'en-US-JennyNeural';

// Text -> MP3 audio buffer (no local playback; data returned to caller).
export async function synthesizeSpeech(text: string, voice = DEFAULT_VOICE): Promise<Buffer> {
  const speechConfig = buildSpeechConfig();
  speechConfig.speechSynthesisVoiceName = voice;
  speechConfig.speechSynthesisOutputFormat =
    sdk.SpeechSynthesisOutputFormat.Audio16Khz32KBitRateMonoMp3;

  const synthesizer = new sdk.SpeechSynthesizer(
    speechConfig,
    null as unknown as sdk.AudioConfig,
  );

  try {
    return await new Promise<Buffer>((resolve, reject) => {
      synthesizer.speakTextAsync(
        text,
        (result) => {
          if (result.reason === sdk.ResultReason.SynthesizingAudioCompleted) {
            resolve(Buffer.from(result.audioData));
          } else {
            reject(new Error(result.errorDetails || 'Speech synthesis failed'));
          }
        },
        (err) => reject(new Error(typeof err === 'string' ? err : 'Speech synthesis error')),
      );
    });
  } finally {
    synthesizer.close();
  }
}
