import { Injectable, CanActivate, ExecutionContext, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class WsJwtGuard implements CanActivate {
  private readonly logger = new Logger(WsJwtGuard.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client = context.switchToWs().getClient();
    const token = client.handshake.auth?.token || client.handshake.headers?.authorization?.split(' ')[1];

    if (!token) {
      this.logger.error('No token found in WS handshake');
      client.disconnect(true);
      return false;
    }

    try {
      const secret = this.configService.get<string>('jwt.secret');
      const payload = this.jwtService.verify(token, { secret });
      client.data.user = payload;
      return true;
    } catch (err) {
      this.logger.error('Invalid token in WS handshake');
      client.disconnect(true);
      return false;
    }
  }
}
