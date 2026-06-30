import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { User } from '@prisma/client';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { VocabService } from './vocab.service';

@ApiTags('vocab')
@ApiBearerAuth()
@Controller('vocab')
@UseGuards(AuthGuard)
export class VocabController {
  constructor(private readonly vocab: VocabService) {}

  @Get()
  list(@CurrentUser() user: User) {
    return this.vocab.list(user.id);
  }
}
