import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type DeviceDocument = HydratedDocument<Device>;

@Schema()
export class Device {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', unique: true, index: true })
  userId!: Types.ObjectId;

  @Prop({ required: true, index: true })
  hardwareId!: string;

  @Prop({ required: true, default: () => new Date() })
  registeredAt!: Date;

  @Prop({ default: true })
  isActive!: boolean;
}

export const DeviceSchema = SchemaFactory.createForClass(Device);
