import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { UpdateStatusDto } from './dto/update-status.dto.js';
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

  @Get()
  @Roles('admin')
  @ApiOperation({ summary: 'List users (admin only)' })
  async findAll(@Query() query: ListUsersQueryDto) {
    const { data, total } = await this.usersService.findAll(query);
    return { data, total, page: query.page, limit: query.limit };
  }

  @Patch(':id/status')
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update user status (admin only)' })
  async updateStatus(@Param('id') id: string, @Body() dto: UpdateStatusDto) {
    return this.usersService.updateStatus(id, dto.status);
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
