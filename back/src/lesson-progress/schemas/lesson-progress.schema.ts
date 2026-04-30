import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type LessonProgressDocument = HydratedDocument<LessonProgress>;

@Schema({ timestamps: true })
export class LessonProgress {
  _id!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Lesson', required: true, index: true })
  lessonId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Subject', required: true, index: true })
  subjectId!: Types.ObjectId;

  @Prop({ type: Number, default: 0 })
  watchedSeconds!: number;

  @Prop({ type: Number, default: 0 })
  durationSeconds!: number;

  @Prop({ type: Boolean, default: false, index: true })
  isCompleted!: boolean;

  @Prop({ type: Date })
  completedAt?: Date;

  @Prop({ type: Date, default: () => new Date() })
  lastWatchedAt!: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const LessonProgressSchema = SchemaFactory.createForClass(LessonProgress);

LessonProgressSchema.index({ userId: 1, lessonId: 1 }, { unique: true });
LessonProgressSchema.index({ userId: 1, subjectId: 1, isCompleted: 1 });
