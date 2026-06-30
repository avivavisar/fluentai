import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { VocabController } from './vocab.controller';
import { VocabService } from './vocab.service';

@Module({
  imports: [AuthModule],
  controllers: [VocabController],
  providers: [VocabService],
})
export class VocabModule {}
