import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { User } from '@prisma/client';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PrismaService } from '../common/prisma/prisma.service';

@ApiTags('user')
@ApiBearerAuth()
@Controller('me')
@UseGuards(AuthGuard)
export class UserController {
  constructor(private readonly prisma: PrismaService) {}

  /** Returns the authenticated user (with profile, if any). */
  @Get()
  async me(@CurrentUser() user: User) {
    const profile = await this.prisma.profile.findUnique({ where: { userId: user.id } });
    return {
      id: user.id,
      email: user.email,
      supabaseId: user.supabaseId,
      uiLanguage: user.uiLanguage,
      createdAt: user.createdAt,
      profile,
    };
  }
}
