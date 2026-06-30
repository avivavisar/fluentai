import { IsArray, IsBoolean, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { Goal, SupportLevel } from '@prisma/client';

/** Fields a learner can update on their profile. All optional (partial update). */
export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  displayName?: string;

  @IsOptional()
  @IsEnum(Goal)
  goal?: Goal;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];

  @IsOptional()
  @IsEnum(SupportLevel)
  hebrewSupportLevel?: SupportLevel;

  @IsOptional()
  @IsBoolean()
  voiceEnabled?: boolean;
}
