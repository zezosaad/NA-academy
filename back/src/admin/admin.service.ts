import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Session, SessionDocument } from '../auth/schemas/session.schema.js';
import { ExamSession, ExamSessionDocument, SessionStatus } from '../exams/schemas/exam-session.schema.js';
import { SubjectCode, SubjectCodeDocument } from '../activation-codes/schemas/subject-code.schema.js';
import { SecurityFlag, SecurityFlagDocument, ActionTaken } from '../security/schemas/security-flag.schema.js';

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(
    @InjectModel(Session.name) private readonly sessionModel: Model<SessionDocument>,
    @InjectModel(ExamSession.name) private readonly examSessionModel: Model<ExamSessionDocument>,
    @InjectModel(SubjectCode.name) private readonly codeModel: Model<SubjectCodeDocument>,
    @InjectModel(SecurityFlag.name) private readonly flagModel: Model<SecurityFlagDocument>,
  ) {}

  async getDashboard() {
    const now = new Date();

    const [
      activeStudentsNow,
      ongoingExams,
      recentActivations,
      securityFlags
    ] = await Promise.all([
      // 1. Active sessions
      this.sessionModel.countDocuments({
        isActive: true,
        expiresAt: { $gt: now }
      }).exec(),

      // 2. Ongoing exams
      this.examSessionModel.countDocuments({
        status: SessionStatus.STARTED,
      }).exec(),

      // 3. Recent Activations (Last 10)
      this.codeModel.find({
        status: 'used' // Using exact mapped string matching enum SubjectCodeStatus.USED
      })
      .sort({ activatedAt: -1 })
      .limit(10)
      .populate('activatedBy', 'name email')
      .exec(),

      // 4. Unreviewed security flags
      this.flagModel.find({
        actionTaken: ActionTaken.NONE
      })
      .sort({ createdAt: -1 })
      .limit(20)
      .populate('studentId', 'name email')
      .exec()
    ]);

    return {
      activeStudentsNow,
      ongoingExams,
      recentActivations,
      securityFlags,
    };
  }
}
