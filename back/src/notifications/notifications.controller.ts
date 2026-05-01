import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Headers,
  Query,
  Param,
  HttpStatus,
  BadRequestException,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiHeader,
  ApiQuery,
  ApiResponse,
  ApiBody,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CreateNotificationDto } from './dto/create-notification.dto.js';
import { NotificationResponseDto } from './dto/notification-response.dto.js';
import { InboxResponseDto } from './dto/recipient-state.dto.js';
import { NotificationsService } from './notifications.service.js';
import { UserRole } from '../users/schemas/user.schema.js';

const UUID_V4_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@ApiTags('Notifications')
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post()
  @Roles('admin', 'teacher')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({ summary: 'Send a push notification to an audience' })
  @ApiHeader({
    name: 'Idempotency-Key',
    description: 'UUID v4 — ensures the request is processed only once',
    required: true,
  })
  @ApiBody({ type: CreateNotificationDto })
  @ApiResponse({
    status: 201,
    type: NotificationResponseDto,
    description: 'Notification sent synchronously',
  })
  @ApiResponse({ status: 202, description: 'Large audience — notification queued asynchronously' })
  @ApiResponse({ status: 400, description: 'Missing or invalid Idempotency-Key header' })
  @ApiResponse({ status: 422, description: 'Audience resolved to zero recipients' })
  async sendNotification(
    @CurrentUser('userId') senderId: string,
    @CurrentUser('role') senderRole: UserRole,
    @Headers('idempotency-key') idempotencyKey: string,
    @Body() dto: CreateNotificationDto,
    @Res() res: Response,
  ): Promise<void> {
    if (!idempotencyKey || !UUID_V4_RE.test(idempotencyKey)) {
      throw new BadRequestException(
        'Idempotency-Key header is required and must be a valid UUID v4',
      );
    }

    const { notification, recipientCount } = await this.notificationsService.send(
      senderId,
      senderRole,
      dto,
      idempotencyKey,
    );

    const responseDto = this.notificationsService.toResponseDto(notification);

    if (recipientCount > 1000) {
      res.status(HttpStatus.ACCEPTED).json(responseDto);
    } else {
      res.status(HttpStatus.CREATED).json(responseDto);
    }
  }

  @Get('me')
  @ApiOperation({ summary: 'Get inbox for the current user' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max items (default 20)' })
  @ApiQuery({
    name: 'before',
    required: false,
    type: String,
    description: 'Cursor (ISO timestamp)',
  })
  @ApiResponse({ status: 200, type: InboxResponseDto })
  async getInbox(
    @CurrentUser('userId') userId: string,
    @Query('limit') limit?: string,
    @Query('before') before?: string,
  ): Promise<InboxResponseDto> {
    const parsedLimit = Math.min(Math.max(parseInt(limit ?? '20', 10) || 20, 1), 100);
    return this.notificationsService.getInbox(userId, parsedLimit, before);
  }

  @Patch('me/:id/read')
  @ApiOperation({ summary: 'Mark a notification as read' })
  @ApiResponse({ status: 200, description: 'Notification marked as read (idempotent)' })
  @ApiResponse({ status: 404, description: 'Notification not found in your inbox' })
  async markRead(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ): Promise<{ ok: boolean }> {
    await this.notificationsService.markRead(userId, id);
    return { ok: true };
  }

  @Post('me/read-all')
  @ApiOperation({ summary: 'Mark all notifications as read for the current user' })
  @ApiResponse({ status: 200, description: 'Returns count of marked-as-read items' })
  async markAllRead(@CurrentUser('userId') userId: string): Promise<{ markedRead: number }> {
    return this.notificationsService.markAllRead(userId);
  }
}
