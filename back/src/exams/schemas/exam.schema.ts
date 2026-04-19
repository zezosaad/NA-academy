import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ExamDocument = HydratedDocument<Exam>;

@Schema()
export class Question {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: String })
  text!: string;

  @Prop({ type: [{ label: { type: String, required: true }, text: { type: String, required: true } }], required: true })
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

  @Prop({ type: [QuestionSchema], required: true, validate: [(val: Question[]) => val.length > 0, 'Must contain at least 1 question'] })
  questions!: Question[];

  @Prop({ default: false, type: Boolean })
  hasFreeSection!: boolean;

  @Prop({ type: Number })
  freeQuestionCount?: number;

  @Prop({ type: Number })
  freeAttemptLimit?: number;

  @Prop({ default: true, index: true, type: Boolean })
  isActive!: boolean;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy?: Types.ObjectId;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamSchema = SchemaFactory.createForClass(Exam);
