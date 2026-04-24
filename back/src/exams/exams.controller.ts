import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiOkResponse, ApiProperty } from '@nestjs/swagger';
import { ExamsService } from './exams.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { CreateExamDto } from './dto/create-exam.dto.js';
import { ListExamsQueryDto } from './dto/list-exams-query.dto.js';
import { UpdateExamDto } from './dto/update-exam.dto.js';
import { SubmitExamDto } from './dto/submit-exam.dto.js';
import { SaveAnswerDto } from './dto/save-answer.dto.js';
import { ActivationCodesService } from '../activation-codes/activation-codes.service.js';

@ApiTags('Exams')
@ApiBearerAuth()
@Controller('exams')
export class ExamsController {
  constructor(
    private readonly examsService: ExamsService,
    private readonly activationCodesService: ActivationCodesService,
  ) {}

  @Post()
  @Roles('admin', 'teacher')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new exam' })
  async createExam(@Body() dto: CreateExamDto, @CurrentUser('userId') userId: string) {
    return this.examsService.createExam(dto, userId);
  }

  @Get()
  @ApiOperation({ summary: 'List exams with per-student attempts remaining' })
  async findAllExams(
    @Query() query: ListExamsQueryDto,
    @CurrentUser('role') role: string,
    @CurrentUser('userId') userId: string,
  ) {
    const { data, total } = await this.examsService.findAllExams(query, role, userId);
    return { data, total, page: query.page, limit: query.limit };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get exam details with free-section filtering logic natively.' })
  async findExamById(
    @Param('id') id: string,
    @CurrentUser('role') role: string,
    @Query('isFree') isFree?: string,
  ) {
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
  async startExam(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Query('isFree') isFree?: string,
  ) {
    const userId = user.userId as string;
    const isFreeAttempt = isFree === 'true';

    if (isFreeAttempt) {
      const check = await this.examsService.canAccessFreeSection(id, userId);
      if (!check.allowed) {
        throw new ForbiddenException('Free attempts exhausted or not available for this exam');
      }
    } else {
      const hasAccess = await this.activationCodesService.hasExamAccess(
        userId,
        id,
        user.hardwareId,
      );
      if (!hasAccess) {
        throw new ForbiddenException(
          'You need to activate this exam code before starting the full exam',
        );
      }
    }

    const session = await this.examsService.startExam(id, userId, isFreeAttempt);
    const exam = await this.examsService.findExamById(id, false);
    if (isFreeAttempt && exam?.hasFreeSection && exam?.freeQuestionCount) {
      exam.questions = exam.questions.slice(0, exam.freeQuestionCount);
    }

    return { session, exam };
  }

  @Post('submit')
  @Roles('student')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Submit exam answers and auto-grade' })
  async submitExam(@Body() dto: SubmitExamDto, @CurrentUser('userId') userId: string) {
    return this.examsService.submitExam(dto, userId);
  }

  @Post('sessions/:sessionId/answer')
  @Roles('student')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Save a single answer for an in-progress exam session (auto-save)' })
  async saveAnswer(
    @Param('sessionId') sessionId: string,
    @Body() dto: SaveAnswerDto,
    @CurrentUser('userId') userId: string,
  ) {
    await this.examsService.saveAnswer(sessionId, userId, dto);
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
