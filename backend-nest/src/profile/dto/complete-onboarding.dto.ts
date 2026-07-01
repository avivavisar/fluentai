import { IsArray, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { Gender, Goal, SupportLevel } from '@prisma/client';

/** Payload to finish onboarding. `goal` is required; the rest are optional. */
export class CompleteOnboardingDto {
  @IsEnum(Goal)
  goal!: Goal;

  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];

  @IsOptional()
  @IsEnum(SupportLevel)
  hebrewSupportLevel?: SupportLevel;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  displayName?: string;
}
