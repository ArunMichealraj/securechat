import { Controller, Get, Param, ParseUUIDPipe, Query, UseGuards } from '@nestjs/common';
import { CurrentUserId, JwtAuthGuard } from '../common/jwt-auth.guard';
import { ChatService } from './chat.service';

@Controller('chats')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chat: ChatService) {}

  @Get()
  list(@CurrentUserId() userId: string) {
    return this.chat.chats(userId);
  }

  @Get(':peerId/messages')
  messages(
    @CurrentUserId() userId: string,
    @Param('peerId', ParseUUIDPipe) peerId: string,
    @Query('before') before?: string,
    @Query('limit') limit?: string,
  ) {
    return this.chat.history(userId, peerId, before ? new Date(before) : undefined, limit ? Number(limit) : 50);
  }
}
