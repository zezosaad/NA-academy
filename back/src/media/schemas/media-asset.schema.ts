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

  @Prop({ required: true, type: Types.ObjectId })
  gridFsFileId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Subject' })
  subjectId?: Types.ObjectId;

  @Prop({ required: true, type: String })
  filename!: string;

  @Prop({ required: true, type: String })
  contentType!: string;

  @Prop({ required: true, type: Number })
  fileSize!: number;

  @Prop({ required: true, enum: MediaType, index: true, type: String })
  mediaType!: MediaType;

  @Prop({ type: String })
  title?: string;

  @Prop({ type: Number })
  order?: number;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  uploadedBy?: Types.ObjectId;

  @Prop({ default: false, type: Boolean })
  chatUpload!: boolean;

  createdAt!: Date;
  updatedAt!: Date;
}

export const MediaAssetSchema = SchemaFactory.createForClass(MediaAsset);
MediaAssetSchema.index({ subjectId: 1, order: 1 });
