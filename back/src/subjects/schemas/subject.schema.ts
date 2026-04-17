import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SubjectDocument = HydratedDocument<Subject>;

@Schema({ timestamps: true })
export class Subject {
  _id!: Types.ObjectId;

  @Prop({ required: true })
  title!: string;

  @Prop()
  description?: string;

  @Prop({ required: true, index: true })
  category!: string;

  @Prop({ default: true, index: true })
  isActive!: boolean;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy?: Types.ObjectId;

  createdAt!: Date;
  updatedAt!: Date;
}

export const SubjectSchema = SchemaFactory.createForClass(Subject);
