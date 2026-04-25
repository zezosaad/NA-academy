import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PasswordResetDocument = HydratedDocument<PasswordReset>;

@Schema({ timestamps: true })
export class PasswordReset {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: String, unique: true, index: true })
  tokenHash!: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  userId!: Types.ObjectId;

  @Prop({ required: true, type: Date })
  expiresAt!: Date;

  @Prop({ required: true, default: false, type: Boolean })
  consumed!: boolean;

  @Prop({ type: Date })
  consumedAt?: Date;
}

export const PasswordResetSchema = SchemaFactory.createForClass(PasswordReset);

PasswordResetSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
