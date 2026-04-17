import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SubjectBundleDocument = HydratedDocument<SubjectBundle>;

@Schema({ timestamps: true })
export class SubjectBundle {
  _id!: Types.ObjectId;

  @Prop({ required: true })
  name!: string;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Subject' }], required: true, validate: [(val: Types.ObjectId[]) => val.length > 0, 'Must contain at least 1 subject'] })
  subjects!: Types.ObjectId[];

  @Prop({ default: true })
  isActive!: boolean;

  createdAt!: Date;
  updatedAt!: Date;
}

export const SubjectBundleSchema = SchemaFactory.createForClass(SubjectBundle);
