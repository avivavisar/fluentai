import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../common/prisma/prisma.service';
import { RedisService } from '../common/redis/redis.service';
import { AiService } from '../ai/ai.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly ai: AiService,
  ) {}

  @Get()
  async check() {
    const result = {
      status: 'ok' as 'ok' | 'degraded',
      db: 'unknown' as string,
      redis: 'unknown' as string,
      ai: this.ai.available() ? 'up' : 'not_configured',
    };

    if (!this.prisma.isConfigured()) {
      result.db = 'not_configured';
    } else {
      try {
        await this.prisma.$queryRaw`SELECT 1`;
        result.db = 'up';
      } catch {
        result.db = 'down';
        result.status = 'degraded';
      }
    }

    if (!this.redis.isConfigured()) {
      result.redis = 'disabled';
    } else {
      result.redis = (await this.redis.ping()) ? 'up' : 'down';
      if (result.redis === 'down') result.status = 'degraded';
    }

    return result;
  }
}
