import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type LessonDocument = HydratedDocument<Lesson>;

@Schema({ timestamps: true })
export class Lesson {
  _id!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Subject', required: true, index: true })
  subjectId!: Types.ObjectId;

  @Prop({ type: String, required: true })
  title!: string;

  @Prop({ type: String })
  description?: string;

  @Prop({ type: Number, default: 0, index: true })
  order!: number;

  @Prop({ type: Types.ObjectId, ref: 'MediaAsset' })
  mediaId?: Types.ObjectId;

  @Prop({ type: Boolean, default: true, index: true })
  isActive!: boolean;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy?: Types.ObjectId;

  createdAt!: Date;
  updatedAt!: Date;
}

export const LessonSchema = SchemaFactory.createForClass(Lesson);
