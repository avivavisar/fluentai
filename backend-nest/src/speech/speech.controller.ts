import { Body, Controller, Post, Res, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { User } from '@prisma/client';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { SpeechService } from './speech.service';
import { TtsDto } from './dto/tts.dto';
import { SttDto } from './dto/stt.dto';

@ApiTags('speech')
@ApiBearerAuth()
@Controller('speech')
@UseGuards(AuthGuard)
export class SpeechController {
  constructor(private readonly speech: SpeechService) {}

  /** Base64 PCM audio → transcript (Azure STT). */
  @Post('stt')
  async stt(@Body() dto: SttDto): Promise<{ text: string }> {
    const text = await this.speech.transcribe(dto.audioBase64);
    return { text };
  }

  /** Text → the learner's tutor voice (MP3). */
  @Post('tts')
  async tts(@CurrentUser() user: User, @Body() dto: TtsDto, @Res() res: Response): Promise<void> {
    const audio = await this.speech.synthesizeForUser(user.id, dto.text);
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Content-Length', audio.length.toString());
    res.end(audio);
  }
}
