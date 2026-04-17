import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ChatMessageDocument = HydratedDocument<ChatMessage>;

export enum ChatMessageType {
  TEXT = 'text',
  IMAGE = 'image',
  FILE = 'file',
}

@Schema({ timestamps: true })
export class ChatMessage {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Subject', index: true })
  subjectId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  senderId!: Types.ObjectId;

  @Prop()
  content?: string;

  @Prop({ required: true, enum: ChatMessageType, default: ChatMessageType.TEXT })
  messageType!: ChatMessageType;

  @Prop()
  fileUrl?: string; // or GridFs ID or public URL

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }] })
  readBy!: Types.ObjectId[];

  createdAt!: Date;
  updatedAt!: Date;
}

export const ChatMessageSchema = SchemaFactory.createForClass(ChatMessage);
