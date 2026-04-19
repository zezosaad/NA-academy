import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SessionDocument = HydratedDocument<Session>;

@Schema({ timestamps: true })
export class Session {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  userId!: Types.ObjectId;

  @Prop({ required: true, type: String })
  hardwareId!: string;

  @Prop({ required: true, type: String })
  refreshTokenHash!: string;

  @Prop({ required: true, index: true, expires: 0, type: Date })
  expiresAt!: Date;

  @Prop({ default: true, type: Boolean })
  isActive!: boolean;
}

export const SessionSchema = SchemaFactory.createForClass(Session);
