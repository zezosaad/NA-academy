import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AdminService } from './admin.service.js';
import { Roles } from '../common/decorators/roles.decorator.js';

@ApiTags('Admin Dashboard')
@ApiBearerAuth()
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  @Roles('admin', 'teacher')
  @ApiOperation({ summary: 'Get unified platform monitoring dashboard data' })
  async getDashboard() {
    return this.adminService.getDashboard();
  }
}
