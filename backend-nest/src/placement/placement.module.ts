import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AiModule } from '../ai/ai.module';
import { PlacementController } from './placement.controller';
import { PlacementService } from './placement.service';

@Module({
  imports: [AuthModule, AiModule],
  controllers: [PlacementController],
  providers: [PlacementService],
})
export class PlacementModule {}
