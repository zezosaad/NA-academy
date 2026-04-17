import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ExamScoreDocument = HydratedDocument<ExamScore>;

@Schema({ timestamps: true })
export class ExamScore {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'ExamSession', unique: true })
  sessionId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  studentId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Exam', index: true })
  examId!: Types.ObjectId;

  @Prop({ required: true })
  totalQuestions!: number;

  @Prop({ required: true })
  correctAnswers!: number;

  @Prop({ required: true })
  scorePercentage!: number;

  @Prop()
  certificateGridFsId?: Types.ObjectId;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ExamScoreSchema = SchemaFactory.createForClass(ExamScore);
