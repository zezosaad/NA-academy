import { Injectable, ConflictException, NotFoundException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument, UserRole, UserStatus } from './schemas/user.schema.js';
import { ListUsersQueryDto } from './dto/list-users-query.dto.js';
import { EducationLevel } from '../common/enums/education-level.enum.js';
import { Session, SessionDocument } from '../auth/schemas/session.schema.js';
import {
  SubjectCode,
  SubjectCodeDocument,
  CodeStatus as SubjectCodeStatus,
} from '../activation-codes/schemas/subject-code.schema.js';
import { ExamCode, ExamCodeDocument } from '../activation-codes/schemas/exam-code.schema.js';
import { WatchTime, WatchTimeDocument } from '../analytics/schemas/watch-time.schema.js';
import { ExamSession, ExamSessionDocument } from '../exams/schemas/exam-session.schema.js';
import { ExamScore, ExamScoreDocument } from '../exams/schemas/exam-score.schema.js';
import { SecurityFlag, SecurityFlagDocument } from '../security/schemas/security-flag.schema.js';
import { DevicesService } from '../devices/devices.service.js';
import { Inject, forwardRef } from '@nestjs/common';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private readonly SALT_ROUNDS = 12;

  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Session.name) private readonly sessionModel: Model<SessionDocument>,
    @InjectModel(SubjectCode.name)
    private readonly subjectCodeModel: Model<SubjectCodeDocument>,
    @InjectModel(ExamCode.name) private readonly examCodeModel: Model<ExamCodeDocument>,
    @InjectModel(WatchTime.name) private readonly watchTimeModel: Model<WatchTimeDocument>,
    @InjectModel(ExamSession.name)
    private readonly examSessionModel: Model<ExamSessionDocument>,
    @InjectModel(ExamScore.name) private readonly examScoreModel: Model<ExamScoreDocument>,
    @InjectModel(SecurityFlag.name)
    private readonly securityFlagModel: Model<SecurityFlagDocument>,
    @Inject(forwardRef(() => DevicesService))
    private readonly devicesService: DevicesService,
  ) {}

  async create(data: {
    email: string;
    password: string;
    name: string;
    role?: UserRole;
    level?: EducationLevel;
  }): Promise<UserDocument> {
    const existing = await this.userModel.findOne({ email: data.email.toLowerCase() }).exec();
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(data.password, this.SALT_ROUNDS);

    const user = new this.userModel({
      email: data.email.toLowerCase(),
      passwordHash,
      name: data.name,
      role: data.role || UserRole.STUDENT,
      status: UserStatus.ACTIVE,
      ...(data.level ? { level: data.level } : {}),
    });

    return user.save();
  }

  async createUser(data: any): Promise<UserDocument> {
    const { password, ...rest } = data;
    const passwordHash = await bcrypt.hash(password, this.SALT_ROUNDS);
    const user = new this.userModel({ ...rest, passwordHash });
    return user.save();
  }

  async createAdminUser(data: any): Promise<UserDocument> {
    const { password, ...rest } = data;
    const passwordHash = await bcrypt.hash(password, this.SALT_ROUNDS);
    const user = new this.userModel({
      ...rest,
      passwordHash,
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
    });
    return user.save();
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email: email.toLowerCase() }).exec();
  }

  async findById(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id).exec();
  }

  async findManyByIds(ids: string[]): Promise<UserDocument[]> {
    const objectIds = ids.filter((id) => Types.ObjectId.isValid(id)).map((id) => new Types.ObjectId(id));
    if (objectIds.length === 0) {
      return [];
    }

    return this.userModel.find({ _id: { $in: objectIds } }).exec();
  }

  async searchUsers(q: string, limit = 20): Promise<Array<{ id: string; name: string; email: string; role: UserRole }>> {
    const normalized = q.trim();
    if (!normalized) {
      return [];
    }

    const regex = new RegExp(`^${normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'i');
    const users = await this.userModel
      .find({
        status: UserStatus.ACTIVE,
        $or: [{ name: regex }, { email: regex }],
      })
      .select('_id name email role')
      .sort({ name: 1 })
      .limit(Math.min(limit, 20))
      .lean()
      .exec();

    return users.map((user) => ({
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
    }));
  }

  async findAll(query: ListUsersQueryDto): Promise<{ data: UserDocument[]; total: number }> {
    const filter: Record<string, any> = {};

    if (query.role) {
      filter.role = query.role;
    }
    if (query.status) {
      filter.status = query.status;
    }
    if (query.search) {
      filter.$or = [
        { name: { $regex: query.search, $options: 'i' } },
        { email: { $regex: query.search, $options: 'i' } },
      ];
    }

    const skip = (query.page - 1) * query.limit;

    const [data, total] = await Promise.all([
      this.userModel
        .find(filter)
        .select('-passwordHash')
        .skip(skip)
        .limit(query.limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.userModel.countDocuments(filter).exec(),
    ]);

    return { data, total };
  }

  async updateStatus(id: string, status: UserStatus): Promise<UserDocument> {
    const user = await this.userModel
      .findByIdAndUpdate(id, { status }, { new: true })
      .select('-passwordHash')
      .exec();

    if (!user) {
      throw new NotFoundException('User not found');
    }

    this.logger.log(`User ${id} status updated to ${status}`);
    return user;
  }

  async validatePassword(user: UserDocument, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.passwordHash);
  }

  async updateLevel(id: string, level: EducationLevel): Promise<UserDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('User not found');
    }
    const user = await this.userModel
      .findByIdAndUpdate(id, { level }, { new: true })
      .select('-passwordHash')
      .exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }
    this.logger.log(`User ${id} level updated to ${level}`);
    return user;
  }

  async findUserDetail(id: string): Promise<any> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('User not found');
    }
    const sId = new Types.ObjectId(id);

    const user = await this.userModel.findById(id).select('-passwordHash').lean().exec();
    if (!user) throw new NotFoundException('User not found');

    const [
      device,
      activeSessions,
      lastSession,
      subjectCodes,
      examCodes,
      watchTimeStats,
      totalWatchSecondsAgg,
      examScores,
      examSessions,
      securityFlags,
    ] = await Promise.all([
      this.devicesService.findByUserId(id),
      this.sessionModel.countDocuments({ userId: sId, isActive: true }).exec(),
      this.sessionModel.findOne({ userId: sId }).sort({ updatedAt: -1 }).lean().exec(),
      this.subjectCodeModel
        .find({ activatedBy: sId, status: SubjectCodeStatus.USED })
        .populate('subjectId', 'title category level')
        .populate('bundleId', 'name')
        .sort({ activatedAt: -1 })
        .lean()
        .exec(),
      this.examCodeModel
        .find({ activatedBy: sId })
        .populate('examId', 'title')
        .sort({ firstActivatedAt: -1, createdAt: -1 })
        .lean()
        .exec(),
      this.watchTimeModel
        .aggregate([
          { $match: { studentId: sId } },
          {
            $group: {
              _id: '$subjectId',
              totalSeconds: { $sum: '$durationSeconds' },
              lastWatched: { $max: '$recordedAt' },
            },
          },
          {
            $lookup: {
              from: 'subjects',
              localField: '_id',
              foreignField: '_id',
              as: 'subject',
            },
          },
          { $unwind: { path: '$subject', preserveNullAndEmptyArrays: true } },
          {
            $project: {
              subjectId: '$_id',
              subjectTitle: '$subject.title',
              totalSeconds: 1,
              lastWatched: 1,
            },
          },
          { $sort: { totalSeconds: -1 } },
        ])
        .exec(),
      this.watchTimeModel
        .aggregate([
          { $match: { studentId: sId } },
          { $group: { _id: null, total: { $sum: '$durationSeconds' } } },
        ])
        .exec(),
      this.examScoreModel
        .find({ studentId: sId })
        .populate('examId', 'title')
        .sort({ createdAt: -1 })
        .limit(10)
        .lean()
        .exec(),
      this.examSessionModel
        .find({ studentId: sId })
        .populate('examId', 'title')
        .sort({ startedAt: -1 })
        .limit(10)
        .lean()
        .exec(),
      this.securityFlagModel
        .find({ studentId: sId })
        .sort({ createdAt: -1 })
        .limit(10)
        .lean()
        .exec(),
    ]);

    const subjectActivations = subjectCodes.map((c: any) => ({
      codeId: c._id,
      code: c.code,
      activatedAt: c.activatedAt,
      activationDeviceId: c.activationDeviceId,
      subject: c.subjectId
        ? {
            id: c.subjectId._id,
            title: c.subjectId.title,
            category: c.subjectId.category,
            level: c.subjectId.level,
          }
        : null,
      bundle: c.bundleId ? { id: c.bundleId._id, name: c.bundleId.name } : null,
    }));

    const examActivations = examCodes.map((c: any) => ({
      codeId: c._id,
      code: c.code,
      status: c.status,
      usageType: c.usageType,
      maxUses: c.maxUses,
      remainingUses: c.remainingUses,
      timeLimitMinutes: c.timeLimitMinutes,
      firstActivatedAt: c.firstActivatedAt,
      exam: c.examId ? { id: c.examId._id, title: c.examId.title } : null,
    }));

    const examAttempts = examSessions.map((s: any) => {
      const score = examScores.find((sc: any) => sc.sessionId?.toString() === s._id.toString());
      return {
        sessionId: s._id,
        examTitle: s.examId?.title || null,
        examId: s.examId?._id || s.examId,
        status: s.status,
        startedAt: s.startedAt,
        completedAt: s.completedAt,
        isFreeAttempt: s.isFreeAttempt,
        scorePercentage: score?.scorePercentage,
        correctAnswers: score?.correctAnswers,
        totalQuestions: score?.totalQuestions,
      };
    });

    const totalWatchSeconds = totalWatchSecondsAgg.length > 0 ? totalWatchSecondsAgg[0].total : 0;

    return {
      profile: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        level: user.level,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
      device: device
        ? {
            hardwareId: device.hardwareId,
            isActive: device.isActive,
            registeredAt: device.registeredAt,
          }
        : null,
      sessions: {
        activeCount: activeSessions,
        lastActivityAt: (lastSession as any)?.updatedAt ?? null,
      },
      activations: {
        subjects: subjectActivations,
        exams: examActivations,
      },
      activity: {
        totalWatchSeconds,
        watchTimeBySubject: watchTimeStats,
        examAttempts,
      },
      securityFlags: securityFlags.map((f: any) => ({
        id: f._id,
        flagType: f.flagType,
        actionTaken: f.actionTaken,
        deviceId: f.deviceId,
        createdAt: f.createdAt,
        reviewedAt: f.reviewedAt,
      })),
    };
  }
}
