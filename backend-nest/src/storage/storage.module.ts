import { Global, Module } from '@nestjs/common';
import { StorageService } from './storage.service';
import { StorageDebugController } from './storage.debug.controller';

@Global()
@Module({
  controllers: [StorageDebugController],
  providers: [StorageService],
  exports: [StorageService],
})
export class StorageModule {}
