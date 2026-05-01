import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PushTokenDocument = HydratedDocument<PushToken>;

@Schema({ timestamps: true })
export class PushToken {
  _id!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId!: Types.ObjectId;

  @Prop({ type: String, required: true })
  token!: string;

  @Prop({ type: String, required: true })
  tokenHash!: string;

  @Prop({ type: String, required: true, enum: ['ios', 'android'] })
  platform!: string;

  @Prop({ type: Types.ObjectId, ref: 'Device' })
  deviceId?: Types.ObjectId;

  @Prop({ type: String })
  appVersion?: string;

  @Prop({ type: Date, required: true })
  lastSeenAt!: Date;

  @Prop({ type: Date })
  tombstonedAt?: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const PushTokenSchema = SchemaFactory.createForClass(PushToken);

PushTokenSchema.index(
  { userId: 1 },
  { unique: true, partialFilterExpression: { tombstonedAt: { $exists: false } } },
);
PushTokenSchema.index(
  { tokenHash: 1 },
  { unique: true, partialFilterExpression: { tombstonedAt: { $exists: false } } },
);
PushTokenSchema.index({ tombstonedAt: 1 });
