import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type NotificationRecipientDocument = HydratedDocument<NotificationRecipient>;

export enum RecipientState {
  PENDING = 'pending',
  DELIVERED = 'delivered',
  FAILED = 'failed',
}

@Schema({ timestamps: true })
export class NotificationRecipient {
  _id!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Notification', required: true })
  notificationId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId!: Types.ObjectId;

  @Prop({ type: String, required: true, enum: RecipientState })
  state!: RecipientState;

  @Prop({ type: String })
  failureReason?: string;

  @Prop({ type: Types.ObjectId, ref: 'PushToken' })
  pushTokenId?: Types.ObjectId;

  @Prop({ type: Date })
  deliveredAt?: Date;

  @Prop({ type: Date })
  readAt?: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const NotificationRecipientSchema = SchemaFactory.createForClass(NotificationRecipient);

NotificationRecipientSchema.index({ notificationId: 1, userId: 1 }, { unique: true });
NotificationRecipientSchema.index({ userId: 1, createdAt: -1 });
NotificationRecipientSchema.index({ userId: 1, readAt: 1 });
NotificationRecipientSchema.index({ createdAt: 1 });
