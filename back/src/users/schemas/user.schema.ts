import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

export enum UserRole {
  STUDENT = 'student',
  TEACHER = 'teacher',
  ADMIN = 'admin',
}

export enum UserStatus {
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  BANNED = 'banned',
}

@Schema({ timestamps: true })
export class User {
  _id!: Types.ObjectId;

  @Prop({ required: true, unique: true, lowercase: true, trim: true, index: true })
  email!: string;

  @Prop({ required: true })
  passwordHash!: string;

  @Prop({ required: true })
  name!: string;

  @Prop({ required: true, enum: UserRole, index: true })
  role!: UserRole;

  @Prop({ enum: UserStatus, default: UserStatus.ACTIVE })
  status!: UserStatus;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Subject' }], default: [] })
  assignedSubjects!: Types.ObjectId[];

  createdAt!: Date;
  updatedAt!: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
