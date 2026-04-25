import { Injectable, UnauthorizedException, ForbiddenException, GoneException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { Session, SessionDocument } from './schemas/session.schema.js';
import { PasswordReset, PasswordResetDocument } from './schemas/password-reset.schema.js';
import { UsersService } from '../users/users.service.js';
import { DevicesService } from '../devices/devices.service.js';
import { MailService } from '../mail/mail.service.js';
import { UserDocument, UserStatus, UserRole } from '../users/schemas/user.schema.js';
import { JwtPayload } from './strategies/jwt.strategy.js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectModel(Session.name) private readonly sessionModel: Model<SessionDocument>,
    @InjectModel(PasswordReset.name) private readonly passwordResetModel: Model<PasswordResetDocument>,
    private readonly usersService: UsersService,
    private readonly devicesService: DevicesService,
    private readonly mailService: MailService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(data: {
    email: string;
    password: string;
    name: string;
    hardwareId: string;
    role?: UserRole;
  }) {
    // Create user
    const user = await this.usersService.create({
      email: data.email,
      password: data.password,
      name: data.name,
      role: data.role,
    });

    // Register device
    await this.devicesService.registerDevice(user._id.toString(), data.hardwareId);

    // Create session and tokens
    const tokens = await this.createSession(user, data.hardwareId);

    return {
      ...tokens,
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
        role: user.role,
      },
    };
  }

  async login(data: { email: string; password: string; hardwareId: string }) {
    // Validate credentials
    const user = await this.usersService.findByEmail(data.email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isValid = await this.usersService.validatePassword(user, data.password);
    if (!isValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check account status
    if (user.status === UserStatus.SUSPENDED) {
      throw new ForbiddenException('Account is suspended');
    }
    if (user.status === UserStatus.BANNED) {
      throw new ForbiddenException('Account is banned');
    }

    // Validate device (skip for admins)
    if (user.role !== UserRole.ADMIN) {
      const device = await this.devicesService.findByUserId(user._id.toString());
      if (device && device.isActive && device.hardwareId !== data.hardwareId) {
        throw new ForbiddenException(
          'Device mismatch. This account is bound to a different device. Contact admin for device reset.',
        );
      }
    }

    // Register/update device if needed
    await this.devicesService.registerDevice(user._id.toString(), data.hardwareId);

    // Delete all existing sessions (single-session enforcement)
    await this.sessionModel.deleteMany({ userId: user._id }).exec();

    // Create new session and tokens
    const tokens = await this.createSession(user, data.hardwareId);

    return {
      ...tokens,
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
        role: user.role,
      },
    };
  }

  async refresh(refreshToken: string) {
    const refreshTokenHash = this.hashToken(refreshToken);

    const session = await this.sessionModel.findOne({ refreshTokenHash, isActive: true }).exec();

    if (!session) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (session.expiresAt < new Date()) {
      await this.sessionModel.deleteOne({ _id: session._id }).exec();
      throw new UnauthorizedException('Refresh token expired');
    }

    // Fetch user for the new token payload
    const user = await this.usersService.findById(session.userId.toString());
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Generate new tokens (rotation)
    const newRefreshToken = this.generateRefreshToken();
    const newRefreshTokenHash = this.hashToken(newRefreshToken);

    const refreshExpiration = this.configService.get<string>('jwt.refreshExpiration') || '7d';
    const expiresAt = this.calculateExpiry(refreshExpiration);

    // Update session with new refresh token
    session.refreshTokenHash = newRefreshTokenHash;
    session.expiresAt = expiresAt;
    await session.save();

    // Generate new access token
    const payload: JwtPayload = {
      sub: user._id.toString(),
      role: user.role,
      hardwareId: session.hardwareId,
      sessionId: session._id.toString(),
    };

    const accessToken = this.jwtService.sign(payload);

    return { accessToken, refreshToken: newRefreshToken };
  }

  async logout(sessionId: string): Promise<void> {
    await this.sessionModel.deleteOne({ _id: new Types.ObjectId(sessionId) }).exec();
    this.logger.log(`Session ${sessionId} deleted`);
  }

  async issueResetToken(email: string): Promise<void> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      this.logger.warn(`Password reset requested for unknown email: ${email}`);
      return;
    }

    const rawToken = crypto.randomBytes(32).toString('base64url');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);

    await this.passwordResetModel.create({
      userId: user._id,
      tokenHash,
      expiresAt,
      consumed: false,
    });

    try {
      await this.mailService.sendPasswordResetEmail(email, rawToken);
      this.logger.log(`Password reset token issued for user ${user._id}`);
    } catch (err) {
      this.logger.error(`Failed to send password reset email to ${email} (user ${user._id}): ${err}`);
    }
  }

  async consumeResetToken(
    token: string,
    newPassword: string,
    hardwareId: string,
  ): Promise<{ user: any; tokens: { accessToken: string; refreshToken: string } }> {
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    const resetDoc = await this.passwordResetModel
      .findOneAndUpdate(
        { tokenHash, consumed: false, expiresAt: { $gt: new Date() } },
        { $set: { consumed: true, consumedAt: new Date() } },
        { new: true },
      )
      .exec();

    if (!resetDoc) {
      throw new GoneException('This reset link is invalid, expired, or has already been used');
    }

    const user = await this.usersService.findById(resetDoc.userId.toString());
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const SALT_ROUNDS = 12;
    user.passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await user.save();

    await this.devicesService.registerDevice(user._id.toString(), hardwareId);
    await this.sessionModel.deleteMany({ userId: user._id }).exec();
    const tokens = await this.createSession(user, hardwareId);

    return {
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
        role: user.role,
      },
      tokens,
    };
  }

  async deleteAllSessions(userId: string): Promise<void> {
    await this.sessionModel.deleteMany({ userId: new Types.ObjectId(userId) }).exec();
    this.logger.log(`All sessions deleted for user ${userId}`);
  }

  private async createSession(
    user: UserDocument,
    hardwareId: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const refreshToken = this.generateRefreshToken();
    const refreshTokenHash = this.hashToken(refreshToken);
    const refreshExpiration = this.configService.get<string>('jwt.refreshExpiration') || '7d';
    const expiresAt = this.calculateExpiry(refreshExpiration);

    const session = new this.sessionModel({
      userId: user._id,
      hardwareId,
      refreshTokenHash,
      expiresAt,
      isActive: true,
    });
    await session.save();

    const payload: JwtPayload = {
      sub: user._id.toString(),
      role: user.role,
      hardwareId,
      sessionId: session._id.toString(),
    };

    const accessToken = this.jwtService.sign(payload);

    return { accessToken, refreshToken };
  }

  private generateRefreshToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private calculateExpiry(duration: string): Date {
    const now = new Date();
    const match = duration.match(/^(\d+)([smhd])$/);
    if (!match) {
      // Default to 7 days
      return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    }

    const value = parseInt(match[1], 10);
    const unit = match[2];

    switch (unit) {
      case 's':
        return new Date(now.getTime() + value * 1000);
      case 'm':
        return new Date(now.getTime() + value * 60 * 1000);
      case 'h':
        return new Date(now.getTime() + value * 60 * 60 * 1000);
      case 'd':
        return new Date(now.getTime() + value * 24 * 60 * 60 * 1000);
      default:
        return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    }
  }
}
