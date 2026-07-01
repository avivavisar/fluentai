import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { User } from '@prisma/client';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { CompanionService } from './companion.service';
import { SelectCompanionDto } from './dto/select-companion.dto';

@ApiTags('companion')
@ApiBearerAuth()
@Controller()
@UseGuards(AuthGuard)
export class CompanionController {
  constructor(private readonly companion: CompanionService) {}

  @Get('companions/presets')
  presets() {
    return this.companion.presets();
  }

  @Get('companion')
  mine(@CurrentUser() user: User) {
    return this.companion.getForUser(user.id);
  }

  @Post('companion')
  select(@CurrentUser() user: User, @Body() dto: SelectCompanionDto) {
    return this.companion.select(user.id, dto.key);
  }
}
