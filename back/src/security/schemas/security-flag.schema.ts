import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SecurityFlagDocument = HydratedDocument<SecurityFlag>;

export enum FlagType {
  SCREEN_RECORDING = 'screen_recording',
  ROOT_JAILBREAK = 'root_jailbreak',
  VPN_PROXY = 'vpn_proxy',
  SUSPICIOUS_ACTIVITY = 'suspicious_activity',
}

export enum ActionTaken {
  NONE = 'none',
  SESSION_TERMINATED = 'session_terminated',
  ACCOUNT_SUSPENDED = 'account_suspended',
  WARNING_ISSUED = 'warning_issued',
}

@Schema({ timestamps: true })
export class SecurityFlag {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  studentId!: Types.ObjectId;

  @Prop({ required: true, enum: FlagType, index: true, type: String })
  flagType!: FlagType;

  @Prop({ type: String })
  deviceId?: string;

  @Prop({ required: true, enum: ActionTaken, default: ActionTaken.NONE, type: String })
  actionTaken!: ActionTaken;

  @Prop({ type: Object })
  metadata?: Record<string, any>;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  reviewedBy?: Types.ObjectId;

  @Prop({ type: Date })
  reviewedAt?: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const SecurityFlagSchema = SchemaFactory.createForClass(SecurityFlag);
SecurityFlagSchema.index({ studentId: 1, createdAt: -1 });
