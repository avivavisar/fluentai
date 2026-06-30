import { Injectable } from '@nestjs/common';
import { Profile } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CompleteOnboardingDto } from './dto/complete-onboarding.dto';

@Injectable()
export class ProfileService {
  constructor(private readonly prisma: PrismaService) {}

  /** Return the user's profile, creating a default one on first access. */
  async getOrCreate(userId: string): Promise<Profile> {
    const existing = await this.prisma.profile.findUnique({ where: { userId } });
    if (existing) return existing;
    return this.prisma.profile.create({ data: { userId } });
  }

  async update(userId: string, dto: UpdateProfileDto): Promise<Profile> {
    await this.getOrCreate(userId);
    return this.prisma.profile.update({ where: { userId }, data: dto });
  }

  /** Persist onboarding answers and mark onboarding complete (atomic). */
  async completeOnboarding(userId: string, dto: CompleteOnboardingDto): Promise<Profile> {
    await this.getOrCreate(userId);
    return this.prisma.profile.update({
      where: { userId },
      data: { ...dto, onboardingComplete: true },
    });
  }
}
