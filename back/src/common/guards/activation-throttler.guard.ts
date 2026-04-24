import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ConfigService } from '@nestjs/config';
import { ThrottlerException } from '@nestjs/throttler';
import {
  ActivationRateLimit,
  ActivationRateLimitDocument,
} from '../../activation-codes/schemas/activation-rate-limit.schema.js';

@Injectable()
export class ActivationThrottlerGuard implements CanActivate {
  private readonly limit: number;
  private readonly windowMinutes: number;

  constructor(
    @InjectModel(ActivationRateLimit.name)
    private readonly rateLimitModel: Model<ActivationRateLimitDocument>,
    configService: ConfigService,
  ) {
    this.limit = configService.get<number>('rateLimit.activationRateLimit') || 5;
    this.windowMinutes = configService.get<number>('rateLimit.activationRateWindowMinutes') || 15;
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user || user.role !== 'student') {
      return true; // Apply only to students
    }

    const key = `activation:${user.userId}:${user.hardwareId}`;
    const now = new Date();

    let record = await this.rateLimitModel.findOne({ key }).exec();

    if (!record) {
      const expiresAt = new Date(now.getTime() + this.windowMinutes * 60000);
      try {
        await this.rateLimitModel.create({
          key,
          attempts: 1,
          windowStart: now,
          expiresAt,
        });
      } catch (err: any) {
        if (err.code === 11000) {
          // Concurrency - another request created it, fetch and increment
          record = await this.rateLimitModel
            .findOneAndUpdate({ key }, { $inc: { attempts: 1 } }, { new: true })
            .exec();
        } else {
          throw err;
        }
      }
      return true;
    }

    // Record exists
    if (record.attempts >= this.limit) {
      const remainingMinutes = Math.ceil((record.expiresAt.getTime() - now.getTime()) / 60000);
      throw new ThrottlerException(
        `Rate limit exceeded. Try again in ${remainingMinutes} minutes.`,
      );
    }

    // Increment attempts
    await this.rateLimitModel.updateOne({ key }, { $inc: { attempts: 1 } }).exec();

    return true;
  }
}
