import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { TASKS_QUEUE } from './queue.constants';

/**
 * The background worker for the `tasks` queue. For M0.4 it just echoes jobs to prove the
 * pipeline works; real jobs (memory extraction, SRS, notifications, reports) plug in here later.
 */
@Processor(TASKS_QUEUE)
export class TasksProcessor extends WorkerHost {
  private readonly logger = new Logger(TasksProcessor.name);

  async process(job: Job): Promise<unknown> {
    this.logger.log(`Processing job ${job.id} (${job.name}): ${JSON.stringify(job.data)}`);
    // Simulate a tiny unit of work.
    await new Promise((resolve) => setTimeout(resolve, 200));
    return { ok: true, echo: job.data, processedAt: new Date().toISOString() };
  }
}
