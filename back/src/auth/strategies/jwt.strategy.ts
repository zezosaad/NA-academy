import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Session, SessionDocument } from '../schemas/session.schema.js';

export interface JwtPayload {
  sub: string;
  role: string;
  hardwareId: string;
  sessionId: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    @InjectModel(Session.name) private readonly sessionModel: Model<SessionDocument>,
  ) {
    const secret = configService.get<string>('jwt.secret');
    if (!secret) {
      throw new Error('JWT_SECRET is not configured');
    }
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload): Promise<Record<string, any>> {
    // Verify the session still exists and is active (single-session enforcement)
    const session = await this.sessionModel
      .findOne({
        _id: new Types.ObjectId(payload.sessionId),
        userId: new Types.ObjectId(payload.sub),
        isActive: true,
      })
      .exec();

    if (!session) {
      throw new UnauthorizedException('Session expired or invalidated');
    }

    return {
      userId: payload.sub,
      role: payload.role,
      hardwareId: payload.hardwareId,
      sessionId: payload.sessionId,
    };
  }
}
