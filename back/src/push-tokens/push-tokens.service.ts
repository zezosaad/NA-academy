import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { createHash } from 'crypto';
import { PushToken, PushTokenDocument } from './schemas/push-token.schema.js';
import { RegisterTokenDto, RefreshTokenDto } from './dto/register-token.dto.js';

@Injectable()
export class PushTokensService {
  private readonly logger = new Logger(PushTokensService.name);

  constructor(@InjectModel(PushToken.name) private readonly pushTokenModel: Model<PushTokenDocument>) {}

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  async register(userId: string, dto: RegisterTokenDto): Promise<PushTokenDocument> {
    const tokenHash = this.hashToken(dto.token);
    const userObjectId = new Types.ObjectId(userId);

    const existingByHash = await this.pushTokenModel.findOne({ tokenHash }).exec();

    if (existingByHash) {
      if (existingByHash.userId.equals(userObjectId)) {
        if (!existingByHash.tombstonedAt) {
          existingByHash.lastSeenAt = new Date();
          if (dto.appVersion) existingByHash.appVersion = dto.appVersion;
          return existingByHash.save();
        }
        existingByHash.tombstonedAt = undefined;
        existingByHash.lastSeenAt = new Date();
        if (dto.appVersion) existingByHash.appVersion = dto.appVersion;
        return existingByHash.save();
      }
      existingByHash.tombstonedAt = new Date();
      await existingByHash.save();
    }

    await this.tombstoneActiveForUser(userId);

    const token = new this.pushTokenModel({
      userId: userObjectId,
      token: dto.token,
      tokenHash,
      platform: dto.platform,
      appVersion: dto.appVersion,
      deviceId: dto.deviceId ? new Types.ObjectId(dto.deviceId) : undefined,
      lastSeenAt: new Date(),
    });

    return token.save();
  }

  async refresh(id: string, userId: string, dto: RefreshTokenDto): Promise<PushTokenDocument> {
    const doc = await this.pushTokenModel.findById(id).exec();
    if (!doc || !doc.userId.equals(new Types.ObjectId(userId))) {
      throw new Error('not-found');
    }

    if (dto.token) {
      const newHash = this.hashToken(dto.token);
      const collision = await this.pushTokenModel.findOne({
        tokenHash: newHash,
        tombstonedAt: { $exists: false },
        _id: { $ne: doc._id },
      });

      if (collision && !collision.userId.equals(doc.userId)) {
        collision.tombstonedAt = new Date();
        await collision.save();
      }

      doc.token = dto.token;
      doc.tokenHash = newHash;
    }

    if (dto.appVersion) doc.appVersion = dto.appVersion;
    doc.lastSeenAt = new Date();

    return doc.save();
  }

  async tombstone(id: string, userId: string): Promise<void> {
    await this.pushTokenModel
      .findOneAndUpdate(
        { _id: new Types.ObjectId(id), userId: new Types.ObjectId(userId) },
        { tombstonedAt: new Date() },
      )
      .exec();
  }

  async tombstoneActiveForUser(userId: string): Promise<void> {
    await this.pushTokenModel
      .updateMany(
        { userId: new Types.ObjectId(userId), tombstonedAt: { $exists: false } },
        { tombstonedAt: new Date() },
      )
      .exec();
  }

  async findActiveForUserIds(userIds: Types.ObjectId[]): Promise<PushTokenDocument[]> {
    if (userIds.length === 0) return [];
    return this.pushTokenModel
      .find({
        userId: { $in: userIds },
        tombstonedAt: { $exists: false },
      })
      .exec();
  }

  async findActiveForUser(userId: string): Promise<PushTokenDocument | null> {
    return this.pushTokenModel
      .findOne({
        userId: new Types.ObjectId(userId),
        tombstonedAt: { $exists: false },
      })
      .exec();
  }
}
