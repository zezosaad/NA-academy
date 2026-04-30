import { Controller, Get, Param, Query, ParseIntPipe, DefaultValuePipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
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

  @Get('conversations/:conversationId/messages')
  @Roles('student', 'teacher', 'admin')
  @ApiOperation({ summary: 'Get message history for a conversation' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'before', required: false, type: String })
  async getConversationMessages(
    @Param('conversationId') conversationId: string,
    @CurrentUser('userId') userId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
    @Query('before') before?: string,
  ) {
    return this.chatService.getConversationMessages(conversationId, userId, limit, before);
  }

  @Get('pending')
  @Roles('student', 'admin', 'teacher')
  @ApiOperation({ summary: 'Get pending offline messages' })
  async getPendingMessages(@CurrentUser('userId') userId: string) {
    return this.chatService.getPendingMessages(userId);
  }
}
