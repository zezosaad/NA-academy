import { Controller, Get, Post, Put, Delete, Body, Param, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SubjectsService } from './subjects.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { CreateSubjectDto } from './dto/create-subject.dto.js';
import { UpdateSubjectDto } from './dto/update-subject.dto.js';
import { CreateBundleDto } from './dto/create-bundle.dto.js';
import { UpdateBundleDto } from './dto/update-bundle.dto.js';
import { ListSubjectsQueryDto } from './dto/list-subjects-query.dto.js';

@ApiTags('Subjects')
@ApiBearerAuth()
@Controller()
export class SubjectsController {
  constructor(private readonly subjectsService: SubjectsService) {}

  // Subjects

  @Post('subjects')
  @Roles('admin', 'teacher')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new subject' })
  async createSubject(@Body() dto: CreateSubjectDto, @CurrentUser('userId') userId: string) {
    return this.subjectsService.createSubject(dto, userId);
  }

  @Get('subjects')
  @ApiOperation({ summary: 'List subjects' })
  async findAllSubjects(@Query() query: ListSubjectsQueryDto, @CurrentUser('role') role: string) {
    const { data, total } = await this.subjectsService.findAllSubjects(query, role);
    return { data, total, page: query.page, limit: query.limit };
  }

  @Get('subjects/:id')
  @ApiOperation({ summary: 'Get subject by ID' })
  async findSubjectById(@Param('id') id: string) {
    return this.subjectsService.findSubjectById(id);
  }

  @Put('subjects/:id')
  @Roles('admin', 'teacher')
  @ApiOperation({ summary: 'Update a subject' })
  async updateSubject(@Param('id') id: string, @Body() dto: UpdateSubjectDto) {
    return this.subjectsService.updateSubject(id, dto);
  }

  @Delete('subjects/:id')
  @Roles('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a subject' })
  async deleteSubject(@Param('id') id: string) {
    await this.subjectsService.deleteSubject(id);
  }

  // Bundles

  @Post('subject-bundles')
  @Roles('admin')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new subject bundle' })
  async createBundle(@Body() dto: CreateBundleDto) {
    return this.subjectsService.createBundle(dto);
  }

  @Get('subject-bundles')
  @Roles('admin')
  @ApiOperation({ summary: 'List subject bundles' })
  async findAllBundles() {
    return this.subjectsService.findAllBundles();
  }

  @Put('subject-bundles/:id')
  @Roles('admin')
  @ApiOperation({ summary: 'Update a subject bundle' })
  async updateBundle(@Param('id') id: string, @Body() dto: UpdateBundleDto) {
    return this.subjectsService.updateBundle(id, dto);
  }

  @Delete('subject-bundles/:id')
  @Roles('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a subject bundle' })
  async deleteBundle(@Param('id') id: string) {
    await this.subjectsService.deleteBundle(id);
  }
}
