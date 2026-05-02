import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  GoneException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
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
import { EducationLevel } from '../common/enums/education-level.enum.js';
import { JwtPayload } from './strategies/jwt.strategy.js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectModel(Session.name) private readonly sessionModel: Model<SessionDocument>,
    @InjectModel(PasswordReset.name)
    private readonly passwordResetModel: Model<PasswordResetDocument>,
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
    level: EducationLevel;
    university: string;
    role?: UserRole;
  }) {
    // Create user
    const user = await this.usersService.create({
      email: data.email,
      password: data.password,
      name: data.name,
      role: data.role,
      level: data.level,
      university: data.university,
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
        level: user.level,
        university: user.university,
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
        level: user.level,
        university: user.university,
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

  /**
   * Issue a 6-digit password-reset code, valid for 15 minutes.
   * Invalidates any previous pending codes for the same user so only the latest works.
   */
  async issueResetCode(email: string): Promise<void> {
    const normalizedEmail = email.trim().toLowerCase();
    const user = await this.usersService.findByEmail(normalizedEmail);
    if (!user) {
      this.logger.warn(`Password reset requested for unknown email: ${maskEmail(normalizedEmail)}`);
      return;
    }

    await this.passwordResetModel
      .updateMany(
        { userId: user._id, consumed: false },
        { $set: { consumed: true, consumedAt: new Date() } },
      )
      .exec();

    const code = generateNumericCode(6);
    const codeHash = crypto.createHash('sha256').update(code).digest('hex');
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.passwordResetModel.create({
      userId: user._id,
      email: normalizedEmail,
      tokenHash: codeHash,
      expiresAt,
      consumed: false,
      attempts: 0,
      verified: false,
    });

    try {
      await this.mailService.sendPasswordResetCodeEmail(normalizedEmail, code, user.name);
      this.logger.log(`Password reset code issued for user ${user._id}`);
    } catch (err) {
      this.logger.error(
        `Failed to send password reset code to ${maskEmail(normalizedEmail)} (user ${user._id}): ${err}`,
      );
    }
  }

  /**
   * Verify a 6-digit code. On success, rotate the doc's tokenHash to a new opaque
   * verification token and shorten its lifetime to 5 minutes. Returns that token
   * for the client to use in the subsequent reset-password call.
   *
   * After 5 wrong attempts the code is permanently consumed and the user must request a new one.
   */
  async verifyResetCode(
    email: string,
    code: string,
  ): Promise<{ verificationToken: string; expiresAt: Date }> {
    const MAX_ATTEMPTS = 5;
    const normalizedEmail = email.trim().toLowerCase();
    const codeHash = crypto.createHash('sha256').update(code).digest('hex');

    const resetDoc = await this.passwordResetModel
      .findOne({
        email: normalizedEmail,
        consumed: false,
        verified: false,
        expiresAt: { $gt: new Date() },
      })
      .sort({ createdAt: -1 })
      .exec();

    if (!resetDoc) {
      throw new GoneException('This code is invalid, expired, or has already been used');
    }

    if (resetDoc.tokenHash !== codeHash) {
      resetDoc.attempts += 1;
      if (resetDoc.attempts >= MAX_ATTEMPTS) {
        resetDoc.consumed = true;
        resetDoc.consumedAt = new Date();
        await resetDoc.save();
        throw new GoneException('Too many incorrect attempts. Please request a new code.');
      }
      await resetDoc.save();
      throw new BadRequestException('The code you entered is incorrect');
    }

    const verificationToken = crypto.randomBytes(32).toString('base64url');
    const verificationTokenHash = crypto
      .createHash('sha256')
      .update(verificationToken)
      .digest('hex');
    const verifiedExpiresAt = new Date(Date.now() + 5 * 60 * 1000);

    resetDoc.tokenHash = verificationTokenHash;
    resetDoc.verified = true;
    resetDoc.verifiedAt = new Date();
    resetDoc.expiresAt = verifiedExpiresAt;
    await resetDoc.save();

    return { verificationToken, expiresAt: verifiedExpiresAt };
  }

  async consumeResetToken(
    token: string,
    newPassword: string,
    hardwareId: string,
  ): Promise<{ accessToken: string; refreshToken: string; user: any }> {
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    const resetDoc = await this.passwordResetModel
      .findOneAndUpdate(
        {
          tokenHash,
          verified: true,
          consumed: false,
          expiresAt: { $gt: new Date() },
        },
        { $set: { consumed: true, consumedAt: new Date() } },
        { new: true },
      )
      .exec();

    if (!resetDoc) {
      throw new GoneException(
        'This password-reset session is invalid, expired, or has already been used',
      );
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
      ...tokens,
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
        role: user.role,
        level: user.level,
        university: user.university,
      },
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

function maskEmail(email: string): string {
  const atIndex = email.indexOf('@');
  if (atIndex <= 0) return '***';
  const local = email.substring(0, atIndex);
  const domain = email.substring(atIndex);
  const visible = local.length <= 2 ? local[0] : local.substring(0, 2);
  return `${visible}***${domain}`;
}

/** Generate a numeric code with crypto-strong digits (rejection-sampled to avoid modulo bias). */
function generateNumericCode(length: number): string {
  let code = '';
  while (code.length < length) {
    const buf = crypto.randomBytes(length);
    for (const byte of buf) {
      if (byte < 250) {
        code += (byte % 10).toString();
        if (code.length === length) break;
      }
    }
  }
  return code;
}
