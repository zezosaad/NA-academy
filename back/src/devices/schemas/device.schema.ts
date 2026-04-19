import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type DeviceDocument = HydratedDocument<Device>;

@Schema()
export class Device {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', unique: true, index: true })
  userId!: Types.ObjectId;

  @Prop({ type: String, required: true, index: true })
  hardwareId!: string;

  @Prop({ type: Date, required: true, default: () => new Date() })
  registeredAt!: Date;

  @Prop({ type: Boolean, default: true })
  isActive!: boolean;
}

export const DeviceSchema = SchemaFactory.createForClass(Device);
