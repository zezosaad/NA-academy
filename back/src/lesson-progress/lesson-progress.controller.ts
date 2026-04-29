import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { LessonProgressService } from './lesson-progress.service.js';
import { UpdateProgressDto } from './dto/update-progress.dto.js';

@ApiTags('LessonProgress')
@ApiBearerAuth()
@Controller()
export class LessonProgressController {
  constructor(
    private readonly lessonProgressService: LessonProgressService,
  ) {}

  @Patch('lessons/:id/progress')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Report watch progress for a lesson. Auto-marks completed at >= 90% watched.',
  })
  async updateProgress(
    @Param('id') lessonId: string,
    @Body() dto: UpdateProgressDto,
    @CurrentUser('userId') userId: string,
    @CurrentUser('role') role: string,
  ) {
    return this.lessonProgressService.updateProgress(userId, lessonId, role, dto);
  }

  @Post('lessons/:id/complete')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Manually mark a lesson as complete (for lessons without video).',
  })
  async markComplete(
    @Param('id') lessonId: string,
    @CurrentUser('userId') userId: string,
    @CurrentUser('role') role: string,
  ) {
    return this.lessonProgressService.markComplete(userId, lessonId, role);
  }

  @Get('users/me/progress')
  @ApiOperation({
    summary:
      'Get progress summaries for the current user across one or more subjects.',
  })
  async getMyProgress(
    @Query('subjectIds') subjectIds: string | undefined,
    @CurrentUser('userId') userId: string,
  ): Promise<Record<string, { completed: number; total: number; percent: number }>> {
    const ids = (subjectIds ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
    const map = await this.lessonProgressService.getSubjectProgressBatch(
      userId,
      ids,
    );
    const result: Record<
      string,
      { completed: number; total: number; percent: number }
    > = {};
    for (const [k, v] of map.entries()) result[k] = v;
    return result;
  }
}
