import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SubjectCodeDocument = HydratedDocument<SubjectCode>;

export enum CodeStatus {
  AVAILABLE = 'available',
  USED = 'used',
  EXPIRED = 'expired', // Admin revocation, etc.
}

@Schema({ timestamps: true })
export class SubjectCode {
  _id!: Types.ObjectId;

  @Prop({ required: true, unique: true, index: true })
  code!: string; // 12 characters

  @Prop({ type: Types.ObjectId, ref: 'Subject' })
  subjectId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'SubjectBundle' })
  bundleId?: Types.ObjectId;

  @Prop({ required: true, enum: CodeStatus, default: CodeStatus.AVAILABLE })
  status!: CodeStatus;

  @Prop({ required: true, index: true })
  batchId!: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  activatedBy?: Types.ObjectId;

  @Prop()
  activatedAt?: Date;

  @Prop()
  activationDeviceId?: string;

  createdAt!: Date;
  updatedAt!: Date;
}

export const SubjectCodeSchema = SchemaFactory.createForClass(SubjectCode);

SubjectCodeSchema.index({ subjectId: 1, status: 1 });
SubjectCodeSchema.index({ bundleId: 1, status: 1 });
