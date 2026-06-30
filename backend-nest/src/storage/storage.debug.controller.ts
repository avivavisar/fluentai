import { Controller, Get, NotFoundException, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { StorageService } from './storage.service';
import { env } from '../config/env';

/** Dev-only endpoint to exercise object storage. Disabled in production. */
@ApiTags('debug')
@Controller('debug/storage')
export class StorageDebugController {
  constructor(private readonly storage: StorageService) {}

  private assertDev(): void {
    if (env.NODE_ENV === 'production') throw new NotFoundException();
  }

  @Get('status')
  status() {
    this.assertDev();
    return { configured: this.storage.isConfigured() };
  }

  @Post('test')
  async test() {
    this.assertDev();
    const content = `hello storage ${new Date().toISOString()}`;
    const path = `debug/m05-${Date.now()}.txt`;
    await this.storage.upload(path, content, 'text/plain');
    const signedUrl = await this.storage.signedUrl(path, 600);
    return { path, signedUrl, content };
  }
}
