import { Injectable, ForbiddenException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Device, DeviceDocument } from './schemas/device.schema.js';

@Injectable()
export class DevicesService {
  private readonly logger = new Logger(DevicesService.name);

  constructor(
    @InjectModel(Device.name) private readonly deviceModel: Model<DeviceDocument>,
  ) {}

  async registerDevice(userId: string, hardwareId: string): Promise<DeviceDocument> {
    // Check if user already has a device
    const existing = await this.deviceModel.findOne({ userId: new Types.ObjectId(userId) }).exec();

    if (existing) {
      // If device exists and is active, validate hardware ID matches
      if (existing.isActive && existing.hardwareId !== hardwareId) {
        throw new ForbiddenException(
          'Device mismatch. This account is bound to a different device. Contact admin for device reset.',
        );
      }

      // If device was reset (inactive), re-register with new hardware ID
      if (!existing.isActive) {
        existing.hardwareId = hardwareId;
        existing.isActive = true;
        existing.registeredAt = new Date();
        return existing.save();
      }

      return existing;
    }

    // New device registration
    const device = new this.deviceModel({
      userId: new Types.ObjectId(userId),
      hardwareId,
      registeredAt: new Date(),
      isActive: true,
    });

    return device.save();
  }

  async findByUserId(userId: string): Promise<DeviceDocument | null> {
    return this.deviceModel.findOne({ userId: new Types.ObjectId(userId) }).exec();
  }

  async validateHardwareId(userId: string, hardwareId: string): Promise<boolean> {
    const device = await this.findByUserId(userId);
    if (!device || !device.isActive) {
      return true; // No device registered yet, or device was reset
    }
    return device.hardwareId === hardwareId;
  }

  async resetDevice(userId: string): Promise<void> {
    const device = await this.deviceModel
      .findOneAndUpdate(
        { userId: new Types.ObjectId(userId) },
        { isActive: false },
        { new: true },
      )
      .exec();

    if (device) {
      this.logger.log(`Device reset for user ${userId}`);
    }
  }
}
