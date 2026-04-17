import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type WatchTimeDocument = HydratedDocument<WatchTime>;

@Schema({ timestamps: true })
export class WatchTime {
  _id!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  studentId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'MediaAsset' })
  mediaAssetId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Subject', index: true })
  subjectId!: Types.ObjectId;

  @Prop({ required: true, default: 0 })
  durationSeconds!: number;

  @Prop({ required: true, default: () => new Date() })
  recordedAt!: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const WatchTimeSchema = SchemaFactory.createForClass(WatchTime);
WatchTimeSchema.index({ studentId: 1, subjectId: 1 });
WatchTimeSchema.index({ studentId: 1, mediaAssetId: 1 });
