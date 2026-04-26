import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Conversation, ConversationDocument } from './schemas/conversation.schema.js';
import {
  Message,
  MessageDocument,
  MessageStatus,
  ChatMessageType,
} from './schemas/message.schema.js';
import { AccessCheckHelper } from '../activation-codes/helpers/access-check.helper.js';
import { User, UserDocument } from '../users/schemas/user.schema.js';
import { Subject, SubjectDocument } from '../subjects/schemas/subject.schema.js';
import {
  SubjectCode,
  SubjectCodeDocument,
  CodeStatus as SubjectCodeStatus,
} from '../activation-codes/schemas/subject-code.schema.js';
import { SubjectBundle, SubjectBundleDocument } from '../subjects/schemas/subject-bundle.schema.js';
import { ConversationPreviewDto } from './dto/conversation-list.dto.js';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    @InjectModel(Conversation.name) private readonly conversationModel: Model<ConversationDocument>,
    @InjectModel(Message.name) private readonly messageModel: Model<MessageDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Subject.name) private readonly subjectModel: Model<SubjectDocument>,
    @InjectModel(SubjectCode.name) private readonly subjectCodeModel: Model<SubjectCodeDocument>,
    @InjectModel(SubjectBundle.name)
    private readonly subjectBundleModel: Model<SubjectBundleDocument>,
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

  async canChat(userId1: string, userId2: string): Promise<boolean> {
    if (!Types.ObjectId.isValid(userId1) || !Types.ObjectId.isValid(userId2)) {
      return false;
    }

    const user1 = await this.userModel.findById(userId1).exec();
    const user2 = await this.userModel.findById(userId2).exec();

    if (!user1 || !user2) return false;

    if (user1.role === 'admin' || user2.role === 'admin') return true;

    if (user1.role === 'teacher' && user2.role === 'teacher') return true;

    const studentId =
      user1.role === 'student' ? userId1 : user2.role === 'student' ? userId2 : null;
    const teacherId =
      user1.role === 'teacher' ? userId1 : user2.role === 'teacher' ? userId2 : null;

    if (!studentId || !teacherId) return false;

    const teacher = user1.role === 'teacher' ? user1 : user2;

    const studentUnlockedIds = await this._getUnlockedSubjectIds(studentId);

    const subjects = await this.subjectModel
      .find({
        _id: { $in: studentUnlockedIds.map((id) => new Types.ObjectId(id)) },
        isActive: true,
      })
      .exec();

    for (const subject of subjects) {
      const teacherAssigned = teacher.assignedSubjects.some((sId) => sId.equals(subject._id));
      if (teacherAssigned) return true;
    }

    return false;
  }

  async listConversations(userId: string): Promise<ConversationPreviewDto[]> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) return [];

    const results: ConversationPreviewDto[] = [];
    const seenCounterpartyIds = new Set<string>();

    const existingConversations = await this.conversationModel
      .find({ participants: new Types.ObjectId(userId) })
      .sort({ lastMessageAt: -1 })
      .exec();

    const studentUnlockedIds =
      user.role === 'student' ? await this._getUnlockedSubjectIds(userId) : [];

    for (const conv of existingConversations) {
      const counterpartyId = conv.participants.find((p) => !p.equals(new Types.ObjectId(userId)));
      if (!counterpartyId) continue;

      const cpIdStr = counterpartyId.toString();
      seenCounterpartyIds.add(cpIdStr);

      const counterparty = await this.userModel
        .findById(counterpartyId)
        .select('name role assignedSubjects')
        .exec();
      if (!counterparty) continue;

      const lastMessage = await this.messageModel
        .findOne({ conversationId: conv._id })
        .sort({ createdAt: -1 })
        .exec();

      const unreadCount = await this.messageModel
        .countDocuments({
          conversationId: conv._id,
          recipientId: new Types.ObjectId(userId),
          status: { $ne: MessageStatus.READ },
        })
        .exec();

      let subjectId = '';
      let subjectTitle = '';

      if (counterparty.role === 'teacher') {
        const teacherSubjects = await this.subjectModel
          .find({ _id: { $in: counterparty.assignedSubjects } })
          .exec();
        for (const sub of teacherSubjects) {
          if (user.role === 'student' && studentUnlockedIds.includes(sub._id.toString())) {
            subjectId = sub._id.toString();
            subjectTitle = sub.title;
            break;
          } else if (user.role !== 'student') {
            subjectId = sub._id.toString();
            subjectTitle = sub.title;
            break;
          }
        }
      } else {
        const mySubjects = await this.subjectModel
          .find({ _id: { $in: user.assignedSubjects } })
          .exec();
        if (mySubjects.length > 0) {
          const counterpartyUnlockedIds = await this._getUnlockedSubjectIds(
            counterpartyId.toString(),
          );
          const matched = mySubjects.find((s) =>
            counterpartyUnlockedIds.includes(s._id.toString()),
          );
          if (matched) {
            subjectId = matched._id.toString();
            subjectTitle = matched.title;
          }
        }
      }

      results.push({
        id: conv._id.toString(),
        virtual: false,
        counterpartyId: cpIdStr,
        counterpartyName: counterparty.name,
        counterpartyAvatarUrl: null,
        subjectId,
        subjectTitle,
        lastMessage: lastMessage
          ? {
              text: lastMessage.text ?? undefined,
              hasImage: lastMessage.messageType === ChatMessageType.IMAGE,
              sentAt: lastMessage.createdAt.toISOString(),
              senderId: lastMessage.senderId.toString(),
              status: lastMessage.status,
            }
          : null,
        unreadCount,
      });
    }

    if (user.role === 'student') {
      const subjects = await this.subjectModel
        .find({
          _id: { $in: studentUnlockedIds.map((id) => new Types.ObjectId(id)) },
          isActive: true,
        })
        .exec();

      for (const subject of subjects) {
        const teachers = await this.userModel
          .find({ role: 'teacher', assignedSubjects: subject._id })
          .exec();

        for (const teacher of teachers) {
          if (seenCounterpartyIds.has(teacher._id.toString())) continue;
          seenCounterpartyIds.add(teacher._id.toString());

          const roomId = this.generateRoomId(userId, teacher._id.toString());
          const existingConv = await this.conversationModel.findOne({ roomId }).exec();
          if (existingConv) continue;

          results.push({
            id: '',
            virtual: true,
            counterpartyId: teacher._id.toString(),
            counterpartyName: teacher.name,
            counterpartyAvatarUrl: null,
            subjectId: subject._id.toString(),
            subjectTitle: subject.title,
            lastMessage: null,
            unreadCount: 0,
          });
        }
      }
    } else if (user.role === 'teacher') {
      const teacherSubjects = user.assignedSubjects;
      const subjects = await this.subjectModel
        .find({ _id: { $in: teacherSubjects }, isActive: true })
        .exec();

      const allStudents = await this.userModel.find({ role: 'student' }).exec();

      for (const subject of subjects) {
        for (const student of allStudents) {
          const studentUnlockedIds = await this._getUnlockedSubjectIds(student._id.toString());
          if (!studentUnlockedIds.includes(subject._id.toString())) continue;
          if (seenCounterpartyIds.has(student._id.toString())) continue;
          seenCounterpartyIds.add(student._id.toString());

          const roomId = this.generateRoomId(userId, student._id.toString());
          const existingConv = await this.conversationModel.findOne({ roomId }).exec();
          if (existingConv) continue;

          results.push({
            id: '',
            virtual: true,
            counterpartyId: student._id.toString(),
            counterpartyName: student.name,
            counterpartyAvatarUrl: null,
            subjectId: subject._id.toString(),
            subjectTitle: subject.title,
            lastMessage: null,
            unreadCount: 0,
          });
        }
      }
    }

    results.sort((a, b) => {
      const aTime = a.lastMessage?.sentAt ?? '0';
      const bTime = b.lastMessage?.sentAt ?? '0';
      return bTime.localeCompare(aTime);
    });

    return results;
  }

  private async _getUnlockedSubjectIds(userId: string): Promise<string[]> {
    const directCodes = await this.subjectCodeModel
      .find({
        activatedBy: new Types.ObjectId(userId),
        status: SubjectCodeStatus.USED,
        subjectId: { $exists: true },
      })
      .exec();

    const subjectIds = new Set<string>();
    for (const code of directCodes) {
      if (code.subjectId) subjectIds.add(code.subjectId.toString());
    }

    const bundleCodes = await this.subjectCodeModel
      .find({
        activatedBy: new Types.ObjectId(userId),
        status: SubjectCodeStatus.USED,
        bundleId: { $exists: true },
      })
      .exec();

    if (bundleCodes.length > 0) {
      const bundleIds = bundleCodes
        .map((c) => c.bundleId)
        .filter((id): id is Types.ObjectId => id !== undefined);

      const bundles = await this.subjectBundleModel.find({ _id: { $in: bundleIds } }).exec();

      for (const bundle of bundles) {
        for (const sId of bundle.subjects ?? []) {
          subjectIds.add(sId.toString());
        }
      }
    }

    return Array.from(subjectIds);
  }

  async saveMessage(data: {
    conversationId: string;
    senderId: string;
    recipientId: string;
    text?: string;
    imageFileId?: string;
    messageType: ChatMessageType;
  }): Promise<MessageDocument> {
    const msg = new this.messageModel({
      ...data,
      conversationId: new Types.ObjectId(data.conversationId),
      senderId: new Types.ObjectId(data.senderId),
      recipientId: new Types.ObjectId(data.recipientId),
      status: MessageStatus.SENT,
    });

    await msg.save();

    await this.conversationModel
      .updateOne({ _id: msg.conversationId }, { lastMessageAt: new Date() })
      .exec();

    return msg.populate('senderId', 'name role email');
  }

  async updateMessageStatus(messageId: string, status: MessageStatus): Promise<void> {
    await this.messageModel.updateOne({ _id: new Types.ObjectId(messageId) }, { status }).exec();
  }

  async markConversationRead(conversationId: string, recipientId: string): Promise<void> {
    await this.messageModel
      .updateMany(
        {
          conversationId: new Types.ObjectId(conversationId),
          recipientId: new Types.ObjectId(recipientId),
          status: { $ne: MessageStatus.READ },
        },
        { $set: { status: MessageStatus.READ } },
      )
      .exec();
  }

  async getPendingMessages(recipientId: string): Promise<MessageDocument[]> {
    return this.messageModel
      .find({
        recipientId: new Types.ObjectId(recipientId),
        status: MessageStatus.SENT,
      })
      .populate('senderId', 'name role email')
      .exec();
  }
}
