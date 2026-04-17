import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SessionDocument = HydratedDocument<Session>;

@Schema({ timestamps: true })
export class Session {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  userId!: Types.ObjectId;

  @Prop({ required: true })
  hardwareId!: string;

  @Prop({ required: true })
  refreshTokenHash!: string;

  @Prop({ required: true, index: true, expires: 0 })
  expiresAt!: Date;

  @Prop({ default: true })
  isActive!: boolean;
}

export const SessionSchema = SchemaFactory.createForClass(Session);
