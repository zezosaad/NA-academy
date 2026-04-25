import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ChatService } from './chat.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import {
  ConversationListResponseDto,
  ConversationPreviewDto,
} from './dto/conversation-list.dto.js';

@ApiTags('Chat')
@ApiBearerAuth()
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('conversations')
  @Roles('student', 'teacher', 'admin')
  @ApiOperation({ summary: 'List conversations for the authenticated user' })
  async listConversations(
    @CurrentUser('userId') userId: string,
  ): Promise<ConversationListResponseDto> {
    const conversations = await this.chatService.listConversations(userId);
    return { conversations };
  }

  @Get('pending')
  @Roles('student', 'admin', 'teacher')
  @ApiOperation({ summary: 'Get pending offline messages' })
  async getPendingMessages(@CurrentUser('userId') userId: string) {
    return this.chatService.getPendingMessages(userId);
  }
}
