import {
  Controller,
  Post,
  Patch,
  Delete,
  Get,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { PushTokensService } from './push-tokens.service.js';
import { RegisterTokenDto, RefreshTokenDto } from './dto/register-token.dto.js';

@ApiTags('Push Tokens')
@ApiBearerAuth()
@Controller('me/push-tokens')
export class PushTokensController {
  constructor(private readonly pushTokensService: PushTokensService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register a new push token' })
  async register(@Req() req: any, @Body() dto: RegisterTokenDto) {
    const userId: string = req.user?.userId;
    const doc = await this.pushTokensService.register(userId, dto);
    return this.toResponse(doc);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Refresh a push token' })
  async refresh(@Req() req: any, @Param('id') id: string, @Body() dto: RefreshTokenDto) {
    const userId: string = req.user?.userId;
    const doc = await this.pushTokensService.refresh(id, userId, dto);
    return this.toResponse(doc);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Tombstone a push token (logout)' })
  async tombstone(@Req() req: any, @Param('id') id: string) {
    const userId: string = req.user?.userId;
    await this.pushTokensService.tombstone(id, userId);
  }

  @Get()
  @ApiOperation({ summary: "List the current user's active push token" })
  async list(@Req() req: any) {
    const userId: string = req.user?.userId;
    const doc = await this.pushTokensService.findActiveForUser(userId);
    return doc ? [this.toResponse(doc)] : [];
  }

  private toResponse(doc: any) {
    return {
      id: (doc._id as any).toString(),
      platform: doc.platform,
      appVersion: doc.appVersion,
      deviceId: doc.deviceId?.toString(),
      lastSeenAt: doc.lastSeenAt.toISOString(),
      createdAt: doc.createdAt.toISOString(),
    };
  }
}
