import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ExamSessionDocument = HydratedDocument<ExamSession>;

export enum SessionStatus {
  STARTED = 'started',
  COMPLETED = 'completed',
  ABANDONED = 'abandoned',
  TIMED_OUT = 'timed_out',
}

@Schema({ timestamps: true })
export class ExamSession {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  studentId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Exam' })
  examId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'ExamCode' })
  examCodeId?: Types.ObjectId;

  @Prop({ required: true, enum: SessionStatus, default: SessionStatus.STARTED })
  status!: SessionStatus;

  @Prop({ required: true })
  startedAt!: Date;

  @Prop()
  completedAt?: Date;

  @Prop()
  timeLimitMinutes?: number;

  @Prop({ type: [{ questionId: { type: Types.ObjectId }, selectedOption: { type: String } }] })
  responses!: { questionId: Types.ObjectId; selectedOption: string }[];

  @Prop({ default: false })
  isFreeAttempt!: boolean;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamSessionSchema = SchemaFactory.createForClass(ExamSession);
