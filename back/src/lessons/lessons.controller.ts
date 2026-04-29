import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { LessonsService } from './lessons.service.js';
import { SubjectsService } from '../subjects/subjects.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { CreateLessonDto } from './dto/create-lesson.dto.js';
import { UpdateLessonDto } from './dto/update-lesson.dto.js';

@ApiTags('Lessons')
@ApiBearerAuth()
@Controller()
export class LessonsController {
  constructor(
    private readonly lessonsService: LessonsService,
    private readonly subjectsService: SubjectsService,
  ) {}

  private async assertStudentUnlocked(
    subjectId: string,
    role: string,
    userId: string,
  ) {
    if (role !== 'student') return;
    const unlockedIds = await this.subjectsService.getUnlockedSubjectIds(userId);
    if (!unlockedIds.has(subjectId)) {
      throw new ForbiddenException('Subject is locked. Activate a code first.');
    }
  }

  @Post('subjects/:subjectId/lessons')
  @Roles('admin', 'teacher')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new lesson under a subject' })
  async create(
    @Param('subjectId') subjectId: string,
    @Body() dto: CreateLessonDto,
    @CurrentUser('userId') userId: string,
  ) {
    return this.lessonsService.create(subjectId, dto, userId);
  }

  @Get('subjects/:subjectId/lessons')
  @ApiOperation({ summary: 'List lessons for a subject (requires unlock for students)' })
  async findBySubject(
    @Param('subjectId') subjectId: string,
    @CurrentUser('role') role: string,
    @CurrentUser('userId') userId: string,
  ) {
    await this.assertStudentUnlocked(subjectId, role, userId);
    return this.lessonsService.findBySubject(
      subjectId,
      role === 'student' ? userId : undefined,
    );
  }

  @Get('lessons/:id')
  @ApiOperation({ summary: 'Get lesson by ID (requires unlock for students)' })
  async findById(
    @Param('id') id: string,
    @CurrentUser('role') role: string,
    @CurrentUser('userId') userId: string,
  ) {
    const lesson = await this.lessonsService.findById(
      id,
      role === 'student' ? userId : undefined,
    );
    await this.assertStudentUnlocked(lesson.subjectId.toString(), role, userId);
    return lesson;
  }

  @Put('lessons/:id')
  @Roles('admin', 'teacher')
  @ApiOperation({ summary: 'Update a lesson' })
  async update(@Param('id') id: string, @Body() dto: UpdateLessonDto) {
    return this.lessonsService.update(id, dto);
  }

  @Delete('lessons/:id')
  @Roles('admin', 'teacher')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a lesson' })
  async remove(@Param('id') id: string) {
    await this.lessonsService.remove(id);
  }
}
