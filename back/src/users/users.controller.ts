import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  HttpCode,
  HttpStatus,
  Req,
  NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { UpdateStatusDto } from './dto/update-status.dto.js';
import { UpdateLevelDto } from './dto/update-level.dto.js';
import { ListUsersQueryDto } from './dto/list-users-query.dto.js';
import { DevicesService } from '../devices/devices.service.js';

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly devicesService: DevicesService,
  ) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  async getMe(@Req() req: any) {
    const user = await this.usersService.findById(req.user.userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return {
      id: user._id.toString(),
      email: user.email,
      name: user.name,
      role: user.role,
      status: user.status,
      level: user.level,
    };
  }

  @Get()
  @Roles('admin')
  @ApiOperation({ summary: 'List users (admin only)' })
  async findAll(@Query() query: ListUsersQueryDto) {
    const { data, total } = await this.usersService.findAll(query);
    return { data, total, page: query.page, limit: query.limit };
  }

  @Get(':id')
  @Roles('admin')
  @ApiOperation({
    summary: 'Get full user detail with activations, activity, and security flags (admin only)',
  })
  async findOne(@Param('id') id: string) {
    return this.usersService.findUserDetail(id);
  }

  @Patch(':id/status')
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update user status (admin only)' })
  async updateStatus(@Param('id') id: string, @Body() dto: UpdateStatusDto) {
    return this.usersService.updateStatus(id, dto.status);
  }

  @Patch(':id/level')
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update user education level (admin only)' })
  async updateLevel(@Param('id') id: string, @Body() dto: UpdateLevelDto) {
    return this.usersService.updateLevel(id, dto.level);
  }

  @Patch(':id/device-reset')
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset user device lock (admin only)' })
  async resetDevice(@Param('id') id: string) {
    await this.devicesService.resetDevice(id);
    return { message: 'Device lock reset' };
  }
}
