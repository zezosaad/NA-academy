import { Controller, Post, Get, Delete, Param, Req, Res, HttpCode, HttpStatus, Headers, ForbiddenException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { MediaService } from './media.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { AccessCheckHelper } from '../activation-codes/helpers/access-check.helper.js';

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
  @ApiOperation({ summary: 'Upload chat image/file asset' })
  async uploadChatMedia(@Req() req: Request, @CurrentUser('userId') userId: string) {
    // Simplified bypass. Uses underlying mediaService uploader
    return this.mediaService.uploadMedia(req, userId);
  }

  @Get('media/:id/stream')
  @Roles('student', 'admin', 'teacher')
  @ApiOperation({ summary: 'Stream media content with byte-range support subject to Activation Code access' })
  async streamMedia(
    @Param('id') id: string, 
    @Headers() headers: any, 
    @Res({ passthrough: false }) res: Response,
    @CurrentUser() user: any
  ) {
    // 1. Fetch asset subject info
    const asset = await this.mediaService.findAssetById(id);
    
    // 2. Check authorization
    if (user.role === 'student' && asset) {
       const hasAccess = await this.accessCheckHelper.hasSubjectAccess(user.userId, asset.subjectId.toString());
       if (!hasAccess) {
         throw new ForbiddenException('You do not have active code access to this media content');
       }
    }

    // 3. Stream content
    const { stream, headers: resHeaders, status } = await this.mediaService.streamFile(id, headers, asset);

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
  async getSubjectMedia(@Param('id') subjectId: string) {
    return this.mediaService.findBySubjectId(subjectId);
  }
}
