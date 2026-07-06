import { join } from 'node:path';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
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
import { ProgressModule } from './progress/progress.module';
import { SpeechModule } from './speech/speech.module';
import { CompanionModule } from './companion/companion.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    // Serve the built Flutter web app so one service hosts both the site and the API.
    // API routes (/v1, /health, /docs) are excluded from the static/SPA fallback.
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'public'),
      exclude: ['/v1*', '/health*', '/docs*'],
      serveStaticOptions: {
        setHeaders: (res: { setHeader: (k: string, v: string) => void }, filePath: string) => {
          // Never cache the files that decide which build everything else is (avoids
          // stranding testers on a stale bundle, esp. iOS Safari).
          if (
            filePath.endsWith('index.html') ||
            filePath.endsWith('flutter_bootstrap.js') ||
            filePath.endsWith('flutter_service_worker.js')
          ) {
            res.setHeader('Cache-Control', 'no-store, must-revalidate');
          }
        },
      },
    }),
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
    ProgressModule,
    CompanionModule,
    SpeechModule,
  ],
})
export class AppModule {}
