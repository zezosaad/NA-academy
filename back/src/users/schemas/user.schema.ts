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

  @Prop({ type: String, required: true, unique: true, lowercase: true, trim: true, index: true })
  email!: string;

  @Prop({ type: String, required: true })
  passwordHash!: string;

  @Prop({ type: String, required: true })
  name!: string;

  @Prop({ type: String, required: true, enum: UserRole, index: true })
  role!: UserRole;

  @Prop({ type: String, enum: UserStatus, default: UserStatus.ACTIVE })
  status!: UserStatus;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Subject' }], default: [] })
  assignedSubjects!: Types.ObjectId[];

  createdAt!: Date;
  updatedAt!: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
