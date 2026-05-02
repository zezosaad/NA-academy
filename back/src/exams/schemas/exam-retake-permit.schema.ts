import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ExamRetakePermitDocument = HydratedDocument<ExamRetakePermit>;

export enum RetakePermitStatus {
  ACTIVE = 'active',
  USED = 'used',
  REVOKED = 'revoked',
}

@Schema({ timestamps: true })
export class ExamRetakePermit {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Exam', index: true })
  examId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  studentId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  grantedBy!: Types.ObjectId;

  @Prop({
    required: true,
    enum: RetakePermitStatus,
    default: RetakePermitStatus.ACTIVE,
    type: String,
    index: true,
  })
  status!: RetakePermitStatus;

  @Prop({ type: Date })
  usedAt?: Date;

  @Prop({ type: Types.ObjectId, ref: 'ExamSession' })
  consumedBySessionId?: Types.ObjectId;

  @Prop({ type: String })
  note?: string;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamRetakePermitSchema = SchemaFactory.createForClass(ExamRetakePermit);

ExamRetakePermitSchema.index(
  { examId: 1, studentId: 1, status: 1 },
  { partialFilterExpression: { status: RetakePermitStatus.ACTIVE } },
);
