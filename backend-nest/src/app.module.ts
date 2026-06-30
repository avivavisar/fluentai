import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './common/prisma/prisma.module';
import { RedisModule } from './common/redis/redis.module';
import { HealthModule } from './health/health.module';
import { AiModule } from './ai/ai.module';
import { AuthModule } from './auth/auth.module';
import { UserModule } from './user/user.module';
import { QueueModule } from './queue/queue.module';
import { StorageModule } from './storage/storage.module';
import { ProfileModule } from './profile/profile.module';
import { PlacementModule } from './placement/placement.module';
import { ConversationModule } from './conversation/conversation.module';
import { VocabModule } from './vocab/vocab.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    RedisModule,
    HealthModule,
    AiModule,
    AuthModule,
    UserModule,
    QueueModule,
    StorageModule,
    ProfileModule,
    PlacementModule,
    ConversationModule,
    VocabModule,
  ],
})
export class AppModule {}
