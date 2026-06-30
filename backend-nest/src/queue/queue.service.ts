import { InjectQueue } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { Queue } from 'bullmq';
import { TASKS_QUEUE } from './queue.constants';

/** Thin façade for enqueuing background jobs. Other modules use this to schedule work. */
@Injectable()
export class QueueService {
  constructor(@InjectQueue(TASKS_QUEUE) private readonly tasks: Queue) {}

  enqueueEcho(message: string) {
    return this.tasks.add(
      'echo',
      { message, at: new Date().toISOString() },
      { removeOnComplete: 100, removeOnFail: 100 },
    );
  }

  counts() {
    return this.tasks.getJobCounts();
  }
}
