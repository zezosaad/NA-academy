import { Injectable, Logger, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Conversation, ConversationDocument } from './schemas/conversation.schema.js';
import { Message, MessageDocument, MessageStatus, ChatMessageType } from './schemas/message.schema.js';
import { AccessCheckHelper } from '../activation-codes/helpers/access-check.helper.js';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    @InjectModel(Conversation.name) private readonly conversationModel: Model<ConversationDocument>,
    @InjectModel(Message.name) private readonly messageModel: Model<MessageDocument>,
    private readonly accessCheckHelper: AccessCheckHelper,
  ) {}

  generateRoomId(userId1: string, userId2: string): string {
    const sorted = [userId1, userId2].sort();
    return `${sorted[0]}_${sorted[1]}`;
  }

  async findOrCreateConversation(userId1: string, userId2: string): Promise<ConversationDocument> {
    const roomId = this.generateRoomId(userId1, userId2);
    let conv = await this.conversationModel.findOne({ roomId }).exec();
    
    if (!conv) {
      conv = new this.conversationModel({
        roomId,
        participants: [new Types.ObjectId(userId1), new Types.ObjectId(userId2)],
        lastMessageAt: new Date(),
      });
      await conv.save();
    }
    return conv;
  }

  async canChat(studentId: string, teacherId: string): Promise<boolean> {
    // Ideally we cross-reference assigned subjects to teacher vs activated student bundles.
    // Assuming for now the teacher has global access or bypass till teacher schedules matrix exists.
    return true; 
  }

  async saveMessage(data: { conversationId: string, senderId: string, recipientId: string, text?: string, imageFileId?: string, messageType: ChatMessageType }): Promise<MessageDocument> {
    const msg = new this.messageModel({
      ...data,
      conversationId: new Types.ObjectId(data.conversationId),
      senderId: new Types.ObjectId(data.senderId),
      recipientId: new Types.ObjectId(data.recipientId),
      status: MessageStatus.SENT,
    });
    
    await msg.save();

    await this.conversationModel.updateOne(
      { _id: msg.conversationId },
      { lastMessageAt: new Date() }
    ).exec();

    return msg.populate('senderId', 'name role email');
  }

  async updateMessageStatus(messageId: string, status: MessageStatus): Promise<void> {
    await this.messageModel.updateOne({ _id: new Types.ObjectId(messageId) }, { status }).exec();
  }

  async markConversationRead(conversationId: string, recipientId: string): Promise<void> {
    await this.messageModel.updateMany(
      { conversationId: new Types.ObjectId(conversationId), recipientId: new Types.ObjectId(recipientId), status: { $ne: MessageStatus.READ } },
      { $set: { status: MessageStatus.READ } }
    ).exec();
  }

  async getPendingMessages(recipientId: string): Promise<MessageDocument[]> {
    return this.messageModel.find({
      recipientId: new Types.ObjectId(recipientId),
      status: MessageStatus.SENT,
    }).populate('senderId', 'name role email').exec();
  }
}
