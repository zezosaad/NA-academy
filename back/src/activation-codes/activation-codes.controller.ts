import { Controller, Get, Post, Patch, Body, Param, Query, Res, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import type { Response } from 'express';
import { ActivationCodesService } from './activation-codes.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { GenerateSubjectCodesDto } from './dto/generate-subject-codes.dto.js';
import { GenerateExamCodesDto } from './dto/generate-exam-codes.dto.js';
import { ListCodesQueryDto } from './dto/list-codes-query.dto.js';
import { BatchExportQueryDto } from './dto/batch-export-query.dto.js';
import { ActivateCodeDto } from './dto/activate-code.dto.js';
import { UseGuards } from '@nestjs/common';
import { ActivationThrottlerGuard } from '../common/guards/activation-throttler.guard.js';

@ApiTags('Activation Codes')
@ApiBearerAuth()
@Controller('activation-codes')
export class ActivationCodesController {
  constructor(private readonly activationCodesService: ActivationCodesService) {}

  @Post('subject/generate')
  @Roles('admin')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Generate bulk activation codes for subjects/bundles' })
  async generateSubjectCodes(@Body() dto: GenerateSubjectCodesDto) {
    return this.activationCodesService.generateSubjectCodes(dto);
  }

  @Post('exam/generate')
  @Roles('admin')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Generate bulk activation codes for exams' })
  async generateExamCodes(@Body() dto: GenerateExamCodesDto) {
    return this.activationCodesService.generateExamCodes(dto);
  }

  @Get('batch/:batchId')
  @Roles('admin')
  @ApiOperation({ summary: 'List codes belonging to a batch' })
  async findByBatch(@Param('batchId') batchId: string, @Query() query: ListCodesQueryDto) {
    const { data, total } = await this.activationCodesService.findByBatch(batchId, query);
    return { data, total, page: query.page, limit: query.limit };
  }

  @Post('batch/:batchId/export')
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Export batch to CSV or XLSX' })
  async exportBatch(@Param('batchId') batchId: string, @Query() query: BatchExportQueryDto, @Res() res: Response) {
    await this.activationCodesService.exportBatch(batchId, query.format, res);
  }

  @Patch(':id/revoke')
  @Roles('admin')
  @ApiOperation({ summary: 'Revoke a single code' })
  async revokeCode(@Param('id') id: string) {
    return this.activationCodesService.revokeCode(id);
  }

  @Patch('batch/:batchId/revoke')
  @Roles('admin')
  @ApiOperation({ summary: 'Revoke all available codes in a batch' })
  async revokeBatch(@Param('batchId') batchId: string) {
    return this.activationCodesService.revokeBatch(batchId);
  }

  @Post('activate')
  @Roles('student')
  @UseGuards(ActivationThrottlerGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Activate a code (Subject or Exam) and lock to device' })
  async activateCode(@Body() dto: ActivateCodeDto, @CurrentUser() user: any) {
    return this.activationCodesService.activateCode(dto.code, user.userId, user.hardwareId);
  }
}
