import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type NotificationDocument = HydratedDocument<Notification>;

export enum AudienceKind {
  ALL = 'all',
  USER_LIST = 'user-list',
  SUBJECT = 'subject',
}

@Schema({ _id: false })
export class AudienceDescriptor {
  @Prop({ type: String, required: true, enum: AudienceKind })
  kind!: AudienceKind;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }] })
  userIds?: Types.ObjectId[];

  @Prop({ type: Types.ObjectId, ref: 'Subject' })
  subjectId?: Types.ObjectId;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], required: true })
  resolvedUserIds!: Types.ObjectId[];

  @Prop({ type: Number, required: true })
  resolvedRecipientCount!: number;
}

@Schema({ _id: false })
export class NotificationStats {
  @Prop({ type: Number, required: true })
  total!: number;

  @Prop({ type: Number, required: true, default: 0 })
  delivered!: number;

  @Prop({ type: Number, required: true, default: 0 })
  failed!: number;

  @Prop({ type: Number, required: true, default: 0 })
  read!: number;
}

@Schema({ timestamps: true })
export class Notification {
  _id!: Types.ObjectId;

  @Prop({ type: String, required: true, trim: true, minlength: 1, maxlength: 100 })
  title!: string;

  @Prop({ type: String, required: true, trim: true, minlength: 1, maxlength: 1000 })
  body!: string;

  @Prop({ type: Map, of: String })
  data?: Map<string, string>;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  senderId!: Types.ObjectId;

  @Prop({ type: String, required: true, enum: ['admin', 'teacher'] })
  senderRole!: string;

  @Prop({ type: AudienceDescriptor, required: true })
  audience!: AudienceDescriptor;

  @Prop({ type: String, required: true })
  idempotencyKey!: string;

  @Prop({ type: NotificationStats, required: true })
  stats!: NotificationStats;

  createdAt!: Date;
  updatedAt!: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

NotificationSchema.index({ senderId: 1, idempotencyKey: 1 }, { unique: true });
NotificationSchema.index({ createdAt: -1 });
NotificationSchema.index({ 'audience.kind': 1, 'audience.subjectId': 1, createdAt: -1 });
NotificationSchema.index({ title: 'text', body: 'text' });
