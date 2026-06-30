import { Body, Controller, Get, NotFoundException, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { QueueService } from './queue.service';
import { env } from '../config/env';

/** Dev-only endpoints to exercise the queue. Disabled in production. */
@ApiTags('debug')
@Controller('debug')
export class DebugController {
  constructor(private readonly queue: QueueService) {}

  private assertDev(): void {
    if (env.NODE_ENV === 'production') {
      throw new NotFoundException();
    }
  }

  @Post('enqueue')
  async enqueue(@Body() body: { message?: string }) {
    this.assertDev();
    const job = await this.queue.enqueueEcho(body?.message ?? 'hello');
    return { enqueued: true, jobId: job.id };
  }

  @Get('counts')
  async counts() {
    this.assertDev();
    return this.queue.counts();
  }
}
