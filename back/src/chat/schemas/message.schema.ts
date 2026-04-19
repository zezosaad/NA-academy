import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type MessageDocument = HydratedDocument<Message>;

export enum ChatMessageType {
  TEXT = 'text',
  IMAGE = 'image',
}

export enum MessageStatus {
  SENT = 'sent',
  DELIVERED = 'delivered',
  READ = 'read',
}

@Schema({ timestamps: true })
export class Message {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Conversation', index: true })
  conversationId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  senderId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  recipientId!: Types.ObjectId;

  @Prop({ required: true, enum: ChatMessageType, default: ChatMessageType.TEXT, type: String })
  messageType!: ChatMessageType;

  @Prop({ type: String })
  text?: string;

  @Prop({ type: String })
  imageFileId?: string;

  @Prop({ required: true, enum: MessageStatus, default: MessageStatus.SENT, type: String })
  status!: MessageStatus;

  createdAt!: Date;
  updatedAt!: Date;
}

export const MessageSchema = SchemaFactory.createForClass(Message);

MessageSchema.index({ conversationId: 1, createdAt: 1 });
MessageSchema.index({ recipientId: 1, status: 1 });
