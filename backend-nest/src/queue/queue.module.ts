import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { buildBullConnection } from './redis-connection';
import { TASKS_QUEUE } from './queue.constants';
import { TasksProcessor } from './tasks.processor';
import { QueueService } from './queue.service';
import { DebugController } from './debug.controller';

@Module({
  imports: [
    BullModule.forRoot({ connection: buildBullConnection() }),
    BullModule.registerQueue({ name: TASKS_QUEUE }),
  ],
  controllers: [DebugController],
  providers: [TasksProcessor, QueueService],
  exports: [QueueService],
})
export class QueueModule {}
