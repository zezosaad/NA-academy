import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ActivationRateLimitDocument = HydratedDocument<ActivationRateLimit>;

@Schema()
export class ActivationRateLimit {
  _id!: Types.ObjectId;

  @Prop({ required: true, unique: true, index: true, type: String })
  key!: string; // Format: activation:{userId}:{hardwareId}

  @Prop({ default: 0, type: Number })
  attempts!: number;

  @Prop({ required: true, type: Date })
  windowStart!: Date;

  @Prop({ required: true, index: { expires: 0 }, type: Date })
  expiresAt!: Date; // TTL index
}

export const ActivationRateLimitSchema = SchemaFactory.createForClass(ActivationRateLimit);
