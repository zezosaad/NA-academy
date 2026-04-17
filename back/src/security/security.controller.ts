import { Controller, Get, Post, Patch, Body, Param, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SecurityService } from './security.service.js';
import { ReportFlagDto, ReviewFlagDto, ListFlagsQueryDto } from './dto/security.dto.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';

@ApiTags('Security')
@ApiBearerAuth()
@Controller('security')
export class SecurityController {
  constructor(private readonly securityService: SecurityService) {}

  @Post('report-flag')
  @Roles('student')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Report a security/anti-piracy flag and auto-terminate sessions' })
  async reportFlag(@Body() dto: ReportFlagDto, @CurrentUser() user: any) {
    return this.securityService.reportFlag(user.userId, user.hardwareId, dto);
  }

  @Get('flags')
  @Roles('admin', 'teacher')
  @ApiOperation({ summary: 'List security flags' })
  async listFlags(@Query() query: ListFlagsQueryDto) {
    return this.securityService.listFlags(query);
  }

  @Patch('flags/:id/review')
  @Roles('admin')
  @ApiOperation({ summary: 'Review and update action taken on a security flag' })
  async reviewFlag(@Param('id') id: string, @Body() dto: ReviewFlagDto, @CurrentUser('userId') adminId: string) {
    return this.securityService.reviewFlag(id, adminId, dto);
  }
}
