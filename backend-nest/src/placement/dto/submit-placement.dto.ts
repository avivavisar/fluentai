import { Type } from 'class-transformer';
import { IsArray, IsOptional, IsString, MaxLength, ValidateNested } from 'class-validator';

class PlacementAnswerDto {
  @IsString()
  id!: string;

  @IsString()
  answer!: string;
}

export class SubmitPlacementDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PlacementAnswerDto)
  answers!: PlacementAnswerDto[];

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  writingSample?: string;
}
