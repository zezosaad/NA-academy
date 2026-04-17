import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type MediaAssetDocument = HydratedDocument<MediaAsset>;

export enum MediaType {
  VIDEO = 'video',
  IMAGE = 'image',
}

@Schema({ timestamps: true })
export class MediaAsset {
  _id!: Types.ObjectId;

  @Prop({ required: true })
  gridFsFileId!: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Subject' })
  subjectId!: Types.ObjectId;

  @Prop({ required: true })
  filename!: string;

  @Prop({ required: true })
  contentType!: string;

  @Prop({ required: true })
  fileSize!: number;

  @Prop({ required: true, enum: MediaType, index: true })
  mediaType!: MediaType;

  @Prop()
  title?: string;

  @Prop()
  order?: number;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  uploadedBy?: Types.ObjectId;

  createdAt!: Date;
  updatedAt!: Date;
}

export const MediaAssetSchema = SchemaFactory.createForClass(MediaAsset);
MediaAssetSchema.index({ subjectId: 1, order: 1 });
