import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ExamDocument = HydratedDocument<Exam>;

@Schema()
export class Question {
  _id!: Types.ObjectId;

  @Prop({ required: true })
  text!: string;

  @Prop({ type: [{ label: { type: String, required: true }, text: { type: String, required: true } }], required: true })
  options!: { label: string; text: string }[];

  @Prop({ required: true })
  correctOption!: string;

  @Prop({ required: true, min: 5 })
  timeLimitSeconds!: number;

  @Prop({ type: Types.ObjectId })
  imageRef?: Types.ObjectId;

  @Prop({ required: true })
  order!: number;
}

export const QuestionSchema = SchemaFactory.createForClass(Question);

@Schema({ timestamps: true })
export class Exam {
  _id!: Types.ObjectId;

  @Prop({ required: true })
  title!: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Subject', index: true })
  subjectId!: Types.ObjectId;

  @Prop({ type: [QuestionSchema], required: true, validate: [(val: Question[]) => val.length > 0, 'Must contain at least 1 question'] })
  questions!: Question[];

  @Prop({ default: false })
  hasFreeSection!: boolean;

  @Prop()
  freeQuestionCount?: number;

  @Prop()
  freeAttemptLimit?: number;

  @Prop({ default: true, index: true })
  isActive!: boolean;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy?: Types.ObjectId;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamSchema = SchemaFactory.createForClass(Exam);
