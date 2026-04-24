import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ChatService } from './chat.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';

@ApiTags('Chat')
@ApiBearerAuth()
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('pending')
  @Roles('student', 'admin', 'teacher')
  @ApiOperation({ summary: 'Get pending offline messages' })
  async getPendingMessages(@CurrentUser('userId') userId: string) {
    return this.chatService.getPendingMessages(userId);
  }
}
