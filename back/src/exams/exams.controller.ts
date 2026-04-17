import { Controller, Get, Post, Put, Delete, Body, Param, Query, HttpCode, HttpStatus, ForbiddenException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ExamsService } from './exams.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { CreateExamDto } from './dto/create-exam.dto.js';
import { UpdateExamDto } from './dto/update-exam.dto.js';
import { SubmitExamDto } from './dto/submit-exam.dto.js';
import { ActivationCodesService } from '../activation-codes/activation-codes.service.js';

@ApiTags('Exams')
@ApiBearerAuth()
@Controller('exams')
export class ExamsController {
  constructor(
    private readonly examsService: ExamsService,
  ) {}

  @Post()
  @Roles('admin', 'teacher')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new exam' })
  async createExam(@Body() dto: CreateExamDto, @CurrentUser('userId') userId: string) {
    return this.examsService.createExam(dto, userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get exam details with free-section filtering logic natively.' })
  async findExamById(@Param('id') id: string, @CurrentUser('role') role: string, @Query('isFree') isFree?: string) {
    const includeAnswers = ['admin', 'teacher'].includes(role);
    const exam = await this.examsService.findExamById(id, includeAnswers);

    if (role === 'student' && isFree === 'true') {
      if (exam.hasFreeSection && exam.freeQuestionCount) {
        exam.questions = exam.questions.slice(0, exam.freeQuestionCount);
      } else {
        throw new ForbiddenException('This exam does not offer a free section');
      }
    }
    
    return exam;
  }

  @Post(':id/start')
  @Roles('student')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Start an exam session natively tracking timing bounds' })
  async startExam(@Param('id') id: string, @CurrentUser('userId') userId: string, @Query('isFree') isFree?: string) {
    const isFreeAttempt = isFree === 'true';

    if (isFreeAttempt) {
      const check = await this.examsService.canAccessFreeSection(id, userId);
      if (!check.allowed) {
        throw new ForbiddenException('Free attempts exhausted or not available for this exam');
      }
    } else {
      // In Production: We should check full `activationCodesService.hasExamAccess(userId, id)` here 
    }

    return this.examsService.startExam(id, userId, isFreeAttempt);
  }

  @Post('submit')
  @Roles('student')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Submit exam answers and auto-grade' })
  async submitExam(@Body() dto: SubmitExamDto, @CurrentUser('userId') userId: string) {
    return this.examsService.submitExam(dto, userId);
  }

  @Put(':id')
  @Roles('admin', 'teacher')
  @ApiOperation({ summary: 'Update an exam' })
  async updateExam(@Param('id') id: string, @Body() dto: UpdateExamDto) {
    return this.examsService.updateExam(id, dto);
  }

  @Delete(':id')
  @Roles('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Soft delete an exam' })
  async deleteExam(@Param('id') id: string) {
    await this.examsService.deleteExam(id);
  }
}
