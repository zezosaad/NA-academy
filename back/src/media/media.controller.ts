import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Req,
  Res,
  HttpCode,
  HttpStatus,
  Headers,
  ForbiddenException,
  PayloadTooLargeException,
  UnsupportedMediaTypeException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { MediaService } from './media.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { AccessCheckHelper } from '../activation-codes/helpers/access-check.helper.js';

const MAX_CHAT_UPLOAD_BYTES = 10 * 1024 * 1024;
const ALLOWED_CHAT_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic']);

@ApiTags('Media')
@ApiBearerAuth()
@Controller()
export class MediaController {
  constructor(
    private readonly mediaService: MediaService,
    private readonly accessCheckHelper: AccessCheckHelper,
  ) {}

  @Post('media/upload')
  @Roles('admin', 'teacher')
  @ApiOperation({ summary: 'Upload media asset (multipart)' })
  async uploadMedia(@Req() req: Request, @CurrentUser('userId') userId: string) {
    return this.mediaService.uploadMedia(req, userId);
  }

  @Post('media/chat/upload')
  @Roles('student', 'teacher')
  @ApiOperation({ summary: 'Upload chat image — 10 MB cap, JPEG/PNG/WebP/HEIC only' })
  async uploadChatMedia(@Req() req: Request, @CurrentUser('userId') userId: string) {
    const contentType = req.headers['content-type'] ?? '';
    const contentLength = parseInt(req.headers['content-length'] as string, 10);

    if (!isNaN(contentLength) && contentLength > MAX_CHAT_UPLOAD_BYTES) {
      throw new PayloadTooLargeException(
        `Chat image must be smaller than ${MAX_CHAT_UPLOAD_BYTES / 1024 / 1024} MB`,
      );
    }

    return this.mediaService.uploadChatMedia(req, userId, {
      maxBytes: MAX_CHAT_UPLOAD_BYTES,
      allowedMimeTypes: ALLOWED_CHAT_MIME_TYPES,
    });
  }

  @Get('media/:id/stream')
  @Roles('student', 'admin', 'teacher')
  @ApiOperation({
    summary: 'Stream media content with byte-range support subject to Activation Code access',
  })
  async streamMedia(
    @Param('id') id: string,
    @Headers() headers: any,
    @Res({ passthrough: false }) res: Response,
    @CurrentUser() user: any,
  ) {
    const asset = await this.mediaService.findAssetById(id);

    if (user.role === 'student' && asset) {
      const hasAccess = await this.accessCheckHelper.hasSubjectAccess(
        user.userId,
        asset.subjectId.toString(),
      );
      if (!hasAccess) {
        throw new ForbiddenException('You do not have active code access to this media content');
      }
    }

    const {
      stream,
      headers: resHeaders,
      status,
    } = await this.mediaService.streamFile(id, headers, asset);

    res.status(status);
    Object.entries(resHeaders).forEach(([key, value]) => {
      res.setHeader(key, value);
    });

    stream.pipe(res);
  }

  @Delete('media/:id')
  @Roles('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete media and its GridFS file' })
  async deleteMedia(@Param('id') id: string) {
    await this.mediaService.deleteMedia(id);
  }

  @Get('subjects/:id/media')
  @ApiOperation({ summary: 'List media assets for a subject' })
  async getSubjectMedia(@Param('id') subjectId: string, @CurrentUser() user: any) {
    if (user?.role === 'student') {
      const hasAccess = await this.accessCheckHelper.hasSubjectAccess(user.userId, subjectId);
      if (!hasAccess) {
        throw new ForbiddenException('You do not have active code access to this subject content');
      }
    }

    return this.mediaService.findBySubjectId(subjectId);
  }
}
