import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { User } from '@prisma/client';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ConversationService } from './conversation.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { PostMessageDto } from './dto/post-message.dto';

@ApiTags('conversations')
@ApiBearerAuth()
@Controller('conversations')
@UseGuards(AuthGuard)
export class ConversationController {
  constructor(private readonly conversations: ConversationService) {}

  @Get()
  list(@CurrentUser() user: User) {
    return this.conversations.list(user.id);
  }

  @Post()
  create(@CurrentUser() user: User, @Body() dto: CreateConversationDto) {
    return this.conversations.create(user.id, dto);
  }

  @Get(':id/messages')
  messages(@CurrentUser() user: User, @Param('id') id: string) {
    return this.conversations.getMessages(user.id, id);
  }

  @Post(':id/messages')
  postMessage(@CurrentUser() user: User, @Param('id') id: string, @Body() dto: PostMessageDto) {
    return this.conversations.postMessage(user.id, id, dto.text);
  }

  @Post(':id/end')
  end(@CurrentUser() user: User, @Param('id') id: string) {
    return this.conversations.end(user.id, id);
  }
}
