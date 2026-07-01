import { IsString } from 'class-validator';

export class SelectCompanionDto {
  @IsString()
  key!: string;
}
