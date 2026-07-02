import { IsString } from 'class-validator';

export class SttDto {
  @IsString()
  audioBase64!: string;
}
