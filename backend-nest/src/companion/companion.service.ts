import { Injectable, NotFoundException } from '@nestjs/common';
import { Companion } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import { findPreset, publicPresets } from './companion-presets';

@Injectable()
export class CompanionService {
  constructor(private readonly prisma: PrismaService) {}

  presets() {
    return { presets: publicPresets() };
  }

  getForUser(userId: string) {
    return this.prisma.companion.findUnique({ where: { userId } });
  }

  async select(userId: string, key: string): Promise<Companion> {
    const preset = findPreset(key);
    if (!preset) throw new NotFoundException('Unknown tutor');
    // Store the preset key in `role` so we can recover pace/accent/voice later (P2 voice).
    return this.prisma.companion.upsert({
      where: { userId },
      create: { userId, name: preset.name, gender: preset.gender, role: preset.key, persona: preset.persona },
      update: { name: preset.name, gender: preset.gender, role: preset.key, persona: preset.persona },
    });
  }
}
