import { IsEnum, IsIn, IsOptional } from 'class-validator';
import { ScenarioMode } from '@prisma/client';

export class CreateConversationDto {
  @IsOptional()
  @IsEnum(ScenarioMode)
  scenario?: ScenarioMode;

  @IsOptional()
  @IsIn(['text', 'voice'])
  mode?: 'text' | 'voice';
}
