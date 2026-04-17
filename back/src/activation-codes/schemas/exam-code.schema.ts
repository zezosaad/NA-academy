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

  @Prop({ required: true, unique: true, index: true })
  code!: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Exam', index: true })
  examId!: Types.ObjectId;

  @Prop({ required: true, enum: ExamUsageType })
  usageType!: ExamUsageType;

  @Prop()
  maxUses?: number;

  @Prop()
  remainingUses?: number;

  @Prop()
  timeLimitMinutes?: number;

  @Prop()
  firstActivatedAt?: Date;

  @Prop({ required: true, enum: CodeStatus, default: CodeStatus.AVAILABLE })
  status!: CodeStatus;

  @Prop({ required: true, index: true })
  batchId!: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  activatedBy?: Types.ObjectId;

  @Prop()
  activationDeviceId?: string;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamCodeSchema = SchemaFactory.createForClass(ExamCode);

ExamCodeSchema.index({ examId: 1, status: 1 });
