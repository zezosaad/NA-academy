import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ExamCodeDocument = HydratedDocument<ExamCode>;

export enum ExamUsageType {
  SINGLE = 'single',
  MULTI = 'multi',
}

export enum CodeStatus {
  AVAILABLE = 'available',
  USED = 'used',
  EXPIRED = 'expired',
}

@Schema({ timestamps: true })
export class ExamCode {
  _id!: Types.ObjectId;

  @Prop({ required: true, unique: true, index: true, type: String })
  code!: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Exam', index: true })
  examId!: Types.ObjectId;

  @Prop({ required: true, enum: ExamUsageType, type: String })
  usageType!: ExamUsageType;

  @Prop({ type: Number })
  maxUses?: number;

  @Prop({ type: Number })
  remainingUses?: number;

  @Prop({ type: Number })
  timeLimitMinutes?: number;

  @Prop({ type: Date })
  firstActivatedAt?: Date;

  @Prop({ required: true, enum: CodeStatus, default: CodeStatus.AVAILABLE, type: String })
  status!: CodeStatus;

  @Prop({ required: true, index: true, type: String })
  batchId!: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  activatedBy?: Types.ObjectId;

  @Prop({ type: String })
  activationDeviceId?: string;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamCodeSchema = SchemaFactory.createForClass(ExamCode);

ExamCodeSchema.index({ examId: 1, status: 1 });
