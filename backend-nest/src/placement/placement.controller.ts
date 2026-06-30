import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { User } from '@prisma/client';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PlacementService } from './placement.service';
import { SubmitPlacementDto } from './dto/submit-placement.dto';

@ApiTags('placement')
@ApiBearerAuth()
@Controller('placement')
@UseGuards(AuthGuard)
export class PlacementController {
  constructor(private readonly placement: PlacementService) {}

  @Get('questions')
  questions() {
    return this.placement.getQuestions();
  }

  @Post('submit')
  submit(@CurrentUser() user: User, @Body() dto: SubmitPlacementDto) {
    return this.placement.submit(user.id, dto);
  }
}
