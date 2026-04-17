import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';
import { Public } from '../common/decorators/public.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Public()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register a new student account' })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register({
      email: dto.email,
      password: dto.password,
      name: dto.name,
      hardwareId: dto.hardwareId,
    });
  }

  @Post('login')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email, password, and device ID' })
  async login(@Body() dto: LoginDto) {
    return this.authService.login({
      email: dto.email,
      password: dto.password,
      hardwareId: dto.hardwareId,
    });
  }

  @Post('refresh')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access token' })
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('logout')
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Logout and invalidate session' })
  async logout(@CurrentUser('sessionId') sessionId: string) {
    await this.authService.logout(sessionId);
    return { message: 'Logged out' };
  }
}
