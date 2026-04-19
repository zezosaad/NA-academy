import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ConversationDocument = HydratedDocument<Conversation>;

@Schema({ timestamps: true })
export class Conversation {
  _id!: Types.ObjectId;

  @Prop({ required: true, unique: true, index: true, type: String })
  roomId!: string; // deterministic from sorted participant IDs

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], required: true, index: true })
  participants!: Types.ObjectId[];

  @Prop({ required: true, default: () => new Date(), index: -1, type: Date })
  lastMessageAt!: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ConversationSchema = SchemaFactory.createForClass(Conversation);
