import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ActivationRateLimitDocument = HydratedDocument<ActivationRateLimit>;

@Schema()
export class ActivationRateLimit {
  _id!: Types.ObjectId;

  @Prop({ required: true, unique: true, index: true })
  key!: string; // Format: activation:{userId}:{hardwareId}

  @Prop({ default: 0 })
  attempts!: number;

  @Prop({ required: true })
  windowStart!: Date;

  @Prop({ required: true, index: { expires: 0 } })
  expiresAt!: Date; // TTL index
}

export const ActivationRateLimitSchema = SchemaFactory.createForClass(ActivationRateLimit);
