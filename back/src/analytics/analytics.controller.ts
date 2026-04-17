import { Controller, Post, Get, Body, Param, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service.js';
import { TrackWatchTimeDto } from './dto/analytics.dto.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';

@ApiTags('Analytics')
@ApiBearerAuth()
@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Post('watch-time')
  @Roles('student')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Track active video watch-time segments' })
  async trackWatchTime(@Body() dto: TrackWatchTimeDto, @CurrentUser('userId') userId: string) {
    return this.analyticsService.trackWatchTime(userId, dto);
  }

  @Get('student/me')
  @Roles('student')
  @ApiOperation({ summary: 'Get current student analytics' })
  async getMyAnalytics(@CurrentUser('userId') userId: string) {
    return this.analyticsService.getStudentAnalytics(userId);
  }

  @Get('student/:studentId')
  @Roles('admin', 'teacher')
  @ApiOperation({ summary: 'Get a specific student analytics profile' })
  async getStudentAnalyticsProfile(@Param('studentId') studentId: string) {
    return this.analyticsService.getStudentAnalytics(studentId);
  }

  @Get('platform')
  @Roles('admin')
  @ApiOperation({ summary: 'Get overall platform aggregated statics' })
  async getPlatformAnalytics() {
    return this.analyticsService.getPlatformAnalytics();
  }
}
