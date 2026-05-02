import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PasswordResetDocument = HydratedDocument<PasswordReset>;

@Schema({ timestamps: true })
export class PasswordReset {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: String, index: true })
  tokenHash!: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  userId!: Types.ObjectId;

  @Prop({ required: true, type: String, lowercase: true, trim: true, index: true })
  email!: string;

  @Prop({ required: true, type: Date })
  expiresAt!: Date;

  @Prop({ required: true, default: false, type: Boolean })
  consumed!: boolean;

  @Prop({ type: Date })
  consumedAt?: Date;

  @Prop({ required: true, default: 0, type: Number })
  attempts!: number;

  @Prop({ required: true, default: false, type: Boolean })
  verified!: boolean;

  @Prop({ type: Date })
  verifiedAt?: Date;
}

export const PasswordResetSchema = SchemaFactory.createForClass(PasswordReset);

PasswordResetSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
