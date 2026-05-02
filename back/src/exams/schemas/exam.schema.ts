import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ExamDocument = HydratedDocument<Exam>;

export enum ExamAccessMode {
  CODE_REQUIRED = 'code_required',
  FREE_SECTION = 'free_section',
  FULL_EXAM_FREE_ATTEMPTS = 'full_exam_free_attempts',
  FREE = 'free',
}

export enum ExamTimingMode {
  PER_QUESTION = 'per_question',
  WHOLE_EXAM = 'whole_exam',
}

@Schema()
export class Question {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: String })
  text!: string;

  @Prop({
    type: [{ label: { type: String, required: true }, text: { type: String, required: true } }],
    required: true,
  })
  options!: { label: string; text: string }[];

  @Prop({ required: true, type: String })
  correctOption!: string;

  @Prop({ required: true, min: 5, type: Number })
  timeLimitSeconds!: number;

  @Prop({ type: Types.ObjectId })
  imageRef?: Types.ObjectId;

  @Prop({ required: true, type: Number })
  order!: number;
}

export const QuestionSchema = SchemaFactory.createForClass(Question);

@Schema({ timestamps: true })
export class Exam {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: String })
  title!: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Subject', index: true })
  subjectId!: Types.ObjectId;

  @Prop({
    type: [QuestionSchema],
    required: true,
    validate: [(val: Question[]) => val.length > 0, 'Must contain at least 1 question'],
  })
  questions!: Question[];

  @Prop({
    enum: ExamAccessMode,
    default: ExamAccessMode.CODE_REQUIRED,
    type: String,
  })
  accessMode!: ExamAccessMode;

  @Prop({
    enum: ExamTimingMode,
    default: ExamTimingMode.PER_QUESTION,
    type: String,
  })
  timingMode!: ExamTimingMode;

  @Prop({ type: Number, min: 1 })
  examTimeLimitMinutes?: number;

  @Prop({ type: Date })
  availableFrom?: Date;

  @Prop({ type: Date })
  availableUntil?: Date;

  @Prop({ default: false, type: Boolean })
  hasFreeSection!: boolean;

  @Prop({ type: Number })
  freeQuestionCount?: number;

  @Prop({ type: Number })
  freeAttemptLimit?: number;

  @Prop({ default: true, index: true, type: Boolean })
  isActive!: boolean;

  @Prop({ type: [Types.ObjectId], ref: 'User', default: [], index: true })
  assignedStudentIds!: Types.ObjectId[];

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy?: Types.ObjectId;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamSchema = SchemaFactory.createForClass(Exam);
