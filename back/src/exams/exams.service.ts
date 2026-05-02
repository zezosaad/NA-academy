import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Exam,
  ExamAccessMode,
  ExamDocument,
  ExamTimingMode,
  Question,
} from './schemas/exam.schema.js';
import { ExamSession, ExamSessionDocument, SessionStatus } from './schemas/exam-session.schema.js';
import { ExamScore, ExamScoreDocument } from './schemas/exam-score.schema.js';
import {
  ExamRetakePermit,
  ExamRetakePermitDocument,
  RetakePermitStatus,
} from './schemas/exam-retake-permit.schema.js';
import {
  ExamCode,
  ExamCodeDocument,
  CodeStatus as ExamCodeStatus,
} from '../activation-codes/schemas/exam-code.schema.js';
import { CreateExamDto } from './dto/create-exam.dto.js';
import { UpdateExamDto } from './dto/update-exam.dto.js';
import { ListExamsQueryDto } from './dto/list-exams-query.dto.js';
import { SubmitExamDto } from './dto/submit-exam.dto.js';
import { SaveAnswerDto } from './dto/save-answer.dto.js';
import { SubjectsService } from '../subjects/subjects.service.js';

@Injectable()
export class ExamsService {
  constructor(
    @InjectModel(Exam.name) private readonly examModel: Model<ExamDocument>,
    @InjectModel(ExamSession.name) private readonly sessionModel: Model<ExamSessionDocument>,
    @InjectModel(ExamScore.name) private readonly scoreModel: Model<ExamScoreDocument>,
    @InjectModel(ExamRetakePermit.name)
    private readonly retakePermitModel: Model<ExamRetakePermitDocument>,
    @InjectModel(ExamCode.name) private readonly examCodeModel: Model<ExamCodeDocument>,
    private readonly subjectsService: SubjectsService,
  ) {}

  private resolveAccessMode(exam: Partial<Exam> | null | undefined): ExamAccessMode {
    if (!exam) {
      return ExamAccessMode.CODE_REQUIRED;
    }

    if (exam.accessMode) {
      return exam.accessMode;
    }

    return exam.hasFreeSection ? ExamAccessMode.FREE_SECTION : ExamAccessMode.CODE_REQUIRED;
  }

  private normalizeExamPayload(dto: CreateExamDto | UpdateExamDto, current?: Partial<Exam>) {
    const accessMode = this.resolveAccessMode({
      ...current,
      ...(dto as Partial<Exam>),
    });
    const timingMode = dto.timingMode ?? current?.timingMode ?? ExamTimingMode.PER_QUESTION;
    const normalized: Record<string, unknown> = {
      ...dto,
      accessMode,
      timingMode,
      hasFreeSection: accessMode === ExamAccessMode.FREE_SECTION,
    };

    if (accessMode !== ExamAccessMode.FREE_SECTION) {
      normalized.freeQuestionCount = undefined;
    }

    if (
      accessMode === ExamAccessMode.CODE_REQUIRED ||
      accessMode === ExamAccessMode.FREE
    ) {
      normalized.freeAttemptLimit = undefined;
    }

    if (timingMode === ExamTimingMode.PER_QUESTION) {
      normalized.examTimeLimitMinutes = undefined;
    }

    if (Array.isArray((dto as CreateExamDto).assignedStudentIds)) {
      normalized.assignedStudentIds = ((dto as CreateExamDto).assignedStudentIds ?? [])
        .filter((id) => Types.ObjectId.isValid(id))
        .map((id) => new Types.ObjectId(id));
    }

    return normalized;
  }

  private getQuestionPool(
    exam: Pick<Exam, 'questions' | 'freeQuestionCount' | 'accessMode' | 'hasFreeSection'>,
    isFreeAttempt: boolean,
  ) {
    const accessMode = this.resolveAccessMode(exam);
    if (!isFreeAttempt) {
      return exam.questions;
    }

    if (accessMode === ExamAccessMode.FREE_SECTION && exam.freeQuestionCount) {
      return exam.questions.slice(0, exam.freeQuestionCount);
    }

    return exam.questions;
  }

  private validateQuestions(questions: any[]) {
    for (const q of questions) {
      const optionLabels = q.options.map((opt: any) => opt.label);
      const normalizedLabels = optionLabels.map((label: string) =>
        String(label || '')
          .trim()
          .toUpperCase(),
      );
      const uniqueLabels = new Set(normalizedLabels);

      if (normalizedLabels.some((label: string) => !label)) {
        throw new BadRequestException(`Question '${q.text}' contains an empty option label`);
      }

      if (uniqueLabels.size !== normalizedLabels.length) {
        throw new BadRequestException(
          `Duplicate option labels are not allowed for question: '${q.text}'`,
        );
      }

      if (!optionLabels.includes(q.correctOption)) {
        throw new BadRequestException(
          `correctOption '${q.correctOption}' does not exist in options for question: '${q.text}'`,
        );
      }
    }
  }

  private validateTiming(dto: CreateExamDto | UpdateExamDto, current?: Partial<Exam>) {
    const timingMode = dto.timingMode ?? current?.timingMode ?? ExamTimingMode.PER_QUESTION;
    const examTimeLimitMinutes = dto.examTimeLimitMinutes ?? current?.examTimeLimitMinutes;

    if (timingMode === ExamTimingMode.WHOLE_EXAM) {
      if (!examTimeLimitMinutes || examTimeLimitMinutes < 1) {
        throw new BadRequestException('Whole exam timing requires examTimeLimitMinutes');
      }
      return;
    }

    if (dto.questions) {
      for (const q of dto.questions) {
        if (!q.timeLimitSeconds || q.timeLimitSeconds < 5) {
          throw new BadRequestException(
            `Question '${q.text}' must have a time limit of at least 5 seconds`,
          );
        }
      }
    }
  }

  private validateAvailability(dto: CreateExamDto | UpdateExamDto, current?: Partial<Exam>) {
    const hasAvailableFrom = Object.prototype.hasOwnProperty.call(dto, 'availableFrom');
    const hasAvailableUntil = Object.prototype.hasOwnProperty.call(dto, 'availableUntil');
    const availableFromValue = hasAvailableFrom ? dto.availableFrom : current?.availableFrom;
    const availableUntilValue = hasAvailableUntil ? dto.availableUntil : current?.availableUntil;

    if (!availableFromValue || !availableUntilValue) return;

    const availableFrom = new Date(availableFromValue);
    const availableUntil = new Date(availableUntilValue);

    if (Number.isNaN(availableFrom.getTime()) || Number.isNaN(availableUntil.getTime())) {
      throw new BadRequestException('Exam availability dates are invalid');
    }

    if (availableFrom >= availableUntil) {
      throw new BadRequestException('Exam availability start must be before the end');
    }
  }

  private isExamAvailableNow(exam: Pick<Exam, 'availableFrom' | 'availableUntil'>) {
    const now = Date.now();
    const availableFrom = exam.availableFrom ? new Date(exam.availableFrom).getTime() : undefined;
    const availableUntil = exam.availableUntil ? new Date(exam.availableUntil).getTime() : undefined;

    if (availableFrom && now < availableFrom) return false;
    if (availableUntil && now > availableUntil) return false;
    return true;
  }

  async createExam(dto: CreateExamDto, userId: string): Promise<ExamDocument> {
    this.validateQuestions(dto.questions);
    this.validateTiming(dto);
    this.validateAvailability(dto);

    const exam = new this.examModel({
      ...this.normalizeExamPayload(dto),
      subjectId: new Types.ObjectId(dto.subjectId),
      createdBy: new Types.ObjectId(userId),
    });
    return exam.save();
  }

  async create(dto: CreateExamDto, userId: string): Promise<ExamDocument> {
    return this.createExam(dto, userId);
  }

  async canAccessFreeAttempt(
    examId: string,
    studentId: string,
  ): Promise<{ allowed: boolean; remainingAttempts: number; accessMode: ExamAccessMode }> {
    const exam = await this.examModel.findById(examId).exec();
    const accessMode = this.resolveAccessMode(exam);
    if (
      !exam ||
      ![ExamAccessMode.FREE_SECTION, ExamAccessMode.FULL_EXAM_FREE_ATTEMPTS].includes(accessMode)
    ) {
      return { allowed: false, remainingAttempts: 0, accessMode };
    }

    // Single-attempt rule: any prior completion blocks free attempts unless a permit is active.
    const completed = await this.hasCompletedAttempt(examId, studentId);
    if (completed) {
      const permit = await this.findActiveRetakePermit(examId, studentId);
      if (!permit) {
        return { allowed: false, remainingAttempts: 0, accessMode };
      }
    }

    return { allowed: true, remainingAttempts: 1, accessMode };
  }

  private async hasCompletedAttempt(examId: string, studentId: string): Promise<boolean> {
    const count = await this.sessionModel
      .countDocuments({
        examId: new Types.ObjectId(examId),
        studentId: new Types.ObjectId(studentId),
        status: { $in: [SessionStatus.COMPLETED, SessionStatus.TIMED_OUT] },
      })
      .exec();
    return count > 0;
  }

  private async findActiveRetakePermit(examId: string, studentId: string) {
    return this.retakePermitModel
      .findOne({
        examId: new Types.ObjectId(examId),
        studentId: new Types.ObjectId(studentId),
        status: RetakePermitStatus.ACTIVE,
      })
      .sort({ createdAt: 1 })
      .exec();
  }

  private isStudentAssigned(exam: Pick<Exam, 'assignedStudentIds'>, studentId: string): boolean {
    if (!exam.assignedStudentIds || exam.assignedStudentIds.length === 0) return false;
    return exam.assignedStudentIds.some((id) => id.toString() === studentId);
  }

  async grantRetakePermit(
    examId: string,
    studentId: string,
    grantedBy: string,
    note?: string,
  ): Promise<ExamRetakePermitDocument> {
    if (!Types.ObjectId.isValid(examId) || !Types.ObjectId.isValid(studentId)) {
      throw new BadRequestException('Invalid exam or student id');
    }
    const exam = await this.examModel.findById(examId).exec();
    if (!exam) throw new NotFoundException('Exam not found');

    const existing = await this.findActiveRetakePermit(examId, studentId);
    if (existing) {
      return existing;
    }

    const permit = new this.retakePermitModel({
      examId: new Types.ObjectId(examId),
      studentId: new Types.ObjectId(studentId),
      grantedBy: new Types.ObjectId(grantedBy),
      status: RetakePermitStatus.ACTIVE,
      note,
    });
    return permit.save();
  }

  async listRetakePermits(examId: string): Promise<any[]> {
    if (!Types.ObjectId.isValid(examId)) return [];
    return this.retakePermitModel
      .find({ examId: new Types.ObjectId(examId) })
      .populate('studentId', 'name email')
      .populate('grantedBy', 'name email')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async revokeRetakePermit(permitId: string): Promise<void> {
    if (!Types.ObjectId.isValid(permitId)) {
      throw new NotFoundException('Permit not found');
    }
    const permit = await this.retakePermitModel.findById(permitId).exec();
    if (!permit) throw new NotFoundException('Permit not found');
    if (permit.status !== RetakePermitStatus.ACTIVE) {
      throw new BadRequestException('Permit is not active');
    }
    permit.status = RetakePermitStatus.REVOKED;
    await permit.save();
  }

  async findExamById(id: string, includeAnswers: boolean = true): Promise<ExamDocument | any> {
    const exam = await this.examModel.findById(id).lean().exec();
    if (!exam) throw new NotFoundException('Exam not found');

    if (!includeAnswers) {
      exam.questions.forEach((q: any) => {
        delete q.correctOption;
      });
    }

    return exam;
  }

  async startExam(
    examId: string,
    studentId: string,
    isFreeAttempt: boolean,
  ): Promise<ExamSessionDocument> {
    const exam = await this.examModel.findById(examId).exec();
    if (!exam) throw new NotFoundException('Exam not found');
    if (!this.isExamAvailableNow(exam)) {
      throw new BadRequestException('Exam is outside its availability window');
    }

    if (exam.assignedStudentIds && exam.assignedStudentIds.length > 0) {
      if (!this.isStudentAssigned(exam, studentId)) {
        throw new ForbiddenException('This exam is not assigned to you');
      }
    }

    const activeSession = await this.sessionModel
      .findOne({
        examId,
        studentId,
        status: SessionStatus.STARTED,
      })
      .exec();

    if (activeSession) {
      return activeSession; // Reconnect
    }

    // Single-attempt rule: any prior completed/timed-out attempt blocks a new session
    // unless an active retake permit is consumed.
    const completedBefore = await this.hasCompletedAttempt(examId, studentId);
    let consumedPermit: ExamRetakePermitDocument | null = null;
    if (completedBefore) {
      consumedPermit = await this.findActiveRetakePermit(examId, studentId);
      if (!consumedPermit) {
        throw new ForbiddenException(
          'You have already taken this exam. Ask the admin to grant a retake.',
        );
      }
    }

    const questionPool = this.getQuestionPool(exam, isFreeAttempt);
    const timeLimitMinutes =
      exam.timingMode === ExamTimingMode.WHOLE_EXAM
        ? (exam.examTimeLimitMinutes ?? 1)
        : Math.ceil(questionPool.reduce((total, q) => total + q.timeLimitSeconds, 0) / 60);

    const session = new this.sessionModel({
      studentId: new Types.ObjectId(studentId),
      examId: exam._id,
      status: SessionStatus.STARTED,
      startedAt: new Date(),
      timeLimitMinutes,
      isFreeAttempt,
    });

    const saved = await session.save();

    if (consumedPermit) {
      consumedPermit.status = RetakePermitStatus.USED;
      consumedPermit.usedAt = new Date();
      consumedPermit.consumedBySessionId = saved._id;
      await consumedPermit.save();
    }

    return saved;
  }

  async submitExam(dto: SubmitExamDto, studentId: string): Promise<ExamScoreDocument> {
    const session = await this.sessionModel.findById(dto.examSessionId).exec();
    if (!session || session.studentId.toString() !== studentId) {
      throw new NotFoundException('Exam session not found');
    }

    if (session.status !== SessionStatus.STARTED) {
      throw new BadRequestException('Exam already submitted');
    }

    const exam = await this.examModel.findById(session.examId).exec();
    if (!exam) throw new NotFoundException('Exam logic error: exam deleted');

    // Auto grader
    let correctAnswers = 0;
    const questionsMap = new Map<string, Question>();

    // In free attempt mode, restrict evaluated total onto limits dynamically
    const questionsPool = this.getQuestionPool(exam, session.isFreeAttempt);

    questionsPool.forEach((q) => questionsMap.set(q._id.toString(), q));

    for (const ans of dto.answers) {
      const q = questionsMap.get(ans.questionId.toString());
      if (q && q.correctOption === ans.selectedOption) {
        correctAnswers++;
      }
    }

    const totalQuestions = questionsPool.length;
    const scorePercentage = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

    // Update session
    session.status = SessionStatus.COMPLETED;
    session.completedAt = new Date();
    session.responses = dto.answers.map((a) => ({
      questionId: new Types.ObjectId(a.questionId),
      selectedOption: a.selectedOption,
    }));
    await session.save();

    // Generate score
    const score = new this.scoreModel({
      sessionId: session._id,
      studentId: new Types.ObjectId(studentId),
      examId: exam._id,
      totalQuestions,
      correctAnswers,
      scorePercentage,
    });

    // Dummy certificate generation if score > 70
    if (scorePercentage >= 70) {
      // Typically uses PDF generator buffer pushed to GridFS `mediaBucket.openUploadStream`
      // Left mocked to return true
      score.certificateGridFsId = new Types.ObjectId();
    }

    return score.save();
  }

  async findAllExams(
    query: ListExamsQueryDto,
    role?: string,
    userId?: string,
  ): Promise<{ data: any[]; total: number }> {
    const filter: Record<string, any> = {};
    if (query.subjectId) {
      filter.subjectId = new Types.ObjectId(query.subjectId);
    }
    if (query.search) {
      filter.title = { $regex: query.search, $options: 'i' };
    }
    if (role === 'student') {
      filter.isActive = true;
    }

    if (role === 'student' && userId) {
      const uId = new Types.ObjectId(userId);
      const unlockedSubjectIds = await this.subjectsService.getUnlockedSubjectIds(userId);

      // Visibility rules:
      // - If exam has assignedStudentIds, only assigned students see it (overrides everything).
      // - Else if user has any subscriptions, only show exams in their unlocked subjects.
      // - Else (no subscriptions, no targeting), show all public (untargeted) exams.
      const hasSubscriptions = unlockedSubjectIds.size > 0;
      const subjectVisibilityClause = hasSubscriptions
        ? {
            $and: [
              {
                subjectId: {
                  $in: [...unlockedSubjectIds]
                    .filter((id) => Types.ObjectId.isValid(id))
                    .map((id) => new Types.ObjectId(id)),
                },
              },
              { $or: [{ assignedStudentIds: { $size: 0 } }, { assignedStudentIds: { $exists: false } }] },
            ],
          }
        : {
            $or: [
              { assignedStudentIds: { $size: 0 } },
              { assignedStudentIds: { $exists: false } },
            ],
          };

      filter.$or = [{ assignedStudentIds: uId }, subjectVisibilityClause];
    }

    const skip = (query.page - 1) * query.limit;

    const [exams, total] = await Promise.all([
      this.examModel
        .find(filter)
        .skip(skip)
        .limit(query.limit)
        .sort({ createdAt: -1 })
        .lean()
        .exec(),
      this.examModel.countDocuments(filter).exec(),
    ]);

    if (role === 'student' && userId) {
      const uId = new Types.ObjectId(userId);
      const examIds = exams.map((e) => e._id);
      const unlockedSubjectIds = await this.subjectsService.getUnlockedSubjectIds(userId);

      const attemptCounts = await this.examCodeModel
        .aggregate<{ _id: Types.ObjectId; count: number }>([
          {
            $match: {
              examId: { $in: examIds },
              status: ExamCodeStatus.AVAILABLE,
              activatedBy: uId,
            },
          },
          { $group: { _id: '$examId', count: { $sum: '$remainingUses' } } },
        ])
        .exec();

      const attemptMap = new Map<string, number>();
      for (const ac of attemptCounts) {
        attemptMap.set(ac._id.toString(), ac.count);
      }

      const latestScores = await this.scoreModel
        .aggregate<{ _id: Types.ObjectId; scorePercentage: number }>([
          { $match: { examId: { $in: examIds }, studentId: uId } },
          { $sort: { createdAt: -1 } },
          { $group: { _id: '$examId', scorePercentage: { $first: '$scorePercentage' } } },
        ])
        .exec();

      const lastScoreMap = new Map<string, number>();
      for (const ls of latestScores) {
        lastScoreMap.set(ls._id.toString(), ls.scorePercentage);
      }

      const completedSessionCounts = await this.sessionModel
        .aggregate<{
          _id: Types.ObjectId;
          completedCount: number;
          startedCount: number;
        }>([
          {
            $match: {
              examId: { $in: examIds },
              studentId: uId,
              status: {
                $in: [SessionStatus.COMPLETED, SessionStatus.STARTED, SessionStatus.TIMED_OUT],
              },
            },
          },
          {
            $group: {
              _id: '$examId',
              completedCount: {
                $sum: {
                  $cond: [
                    { $in: ['$status', [SessionStatus.COMPLETED, SessionStatus.TIMED_OUT]] },
                    1,
                    0,
                  ],
                },
              },
              startedCount: {
                $sum: { $cond: [{ $eq: ['$status', SessionStatus.STARTED] }, 1, 0] },
              },
            },
          },
        ])
        .exec();

      const completedMap = new Map<string, number>();
      const startedMap = new Map<string, number>();
      for (const sc of completedSessionCounts) {
        completedMap.set(sc._id.toString(), sc.completedCount);
        startedMap.set(sc._id.toString(), sc.startedCount);
      }

      const activePermits = await this.retakePermitModel
        .find({
          examId: { $in: examIds },
          studentId: uId,
          status: RetakePermitStatus.ACTIVE,
        })
        .select('examId')
        .lean()
        .exec();

      const permitSet = new Set<string>();
      for (const p of activePermits) {
        permitSet.add(p.examId.toString());
      }

      const data = exams.map((exam) => {
        const availableCodes = attemptMap.get(exam._id.toString()) ?? 0;
        const completedAttempts = completedMap.get(exam._id.toString()) ?? 0;
        const hasStartedSession = (startedMap.get(exam._id.toString()) ?? 0) > 0;
        const hasActivePermit = permitSet.has(exam._id.toString());
        const accessMode = this.resolveAccessMode(exam);
        const isSubjectUnlocked = unlockedSubjectIds.has(exam.subjectId.toString());
        const isAssigned = this.isStudentAssigned(exam as Exam, userId);
        const isAvailableNow = this.isExamAvailableNow(exam);

        // Single-attempt rule: completed = locked unless an active permit exists.
        const lockedByCompletion = completedAttempts > 0 && !hasActivePermit;

        // Determine entitlement to take the exam.
        const isFreeAccess =
          accessMode === ExamAccessMode.FREE ||
          accessMode === ExamAccessMode.FULL_EXAM_FREE_ATTEMPTS ||
          accessMode === ExamAccessMode.FREE_SECTION;

        const hasEntitlement =
          isAssigned ||
          isSubjectUnlocked ||
          isFreeAccess ||
          availableCodes > 0 ||
          hasStartedSession;

        let status: string;
        if (completedAttempts > 0 && !hasActivePermit) {
          status = 'completed';
        } else if (!isAvailableNow) {
          status = 'locked';
        } else if (hasEntitlement) {
          status = 'available';
        } else {
          status = 'locked';
        }

        return {
          ...exam,
          accessMode,
          isSubjectUnlocked,
          isAssigned,
          hasRetakePermit: hasActivePermit,
          attemptsRemaining: lockedByCompletion ? 0 : Math.max(0, availableCodes),
          // Single-attempt rule: at most one attempt is ever available.
          freeAttemptsRemaining:
            !isFreeAccess || lockedByCompletion ? 0 : 1,
          lastScore: lastScoreMap.get(exam._id.toString()) ?? 0,
          status,
        };
      });
      return { data, total };
    }

    const data = exams.map((exam) => ({
      ...exam,
      accessMode: this.resolveAccessMode(exam),
      isSubjectUnlocked: false,
      isAssigned: false,
      hasRetakePermit: false,
      attemptsRemaining: 0,
      freeAttemptsRemaining: exam.freeAttemptLimit ?? 0,
      status: 'available' as string,
    }));
    return { data, total };
  }

  async updateExam(id: string, dto: UpdateExamDto): Promise<ExamDocument> {
    const existing = await this.examModel.findById(id).exec();
    if (!existing) throw new NotFoundException('Exam not found');

    if (dto.questions) {
      this.validateQuestions(dto.questions);
    }
    this.validateTiming(dto, existing);
    this.validateAvailability(dto, existing);

    const updateData: any = this.normalizeExamPayload(dto, existing);
    if (dto.subjectId) {
      updateData.subjectId = new Types.ObjectId(dto.subjectId);
    }

    const exam = await this.examModel.findByIdAndUpdate(id, updateData, { new: true }).exec();
    if (!exam) throw new NotFoundException('Exam not found');
    return exam;
  }

  async deleteExam(id: string): Promise<void> {
    const exam = await this.examModel.findByIdAndUpdate(id, { isActive: false }).exec();
    if (!exam) throw new NotFoundException('Exam not found');
  }

  async saveAnswer(sessionId: string, userId: string, dto: SaveAnswerDto): Promise<void> {
    const session = await this.sessionModel.findById(sessionId).exec();
    if (!session) {
      throw new NotFoundException('Exam session not found');
    }
    if (session.studentId.toString() !== userId) {
      throw new ForbiddenException('You can only answer your own exam session');
    }
    if (session.status !== SessionStatus.STARTED) {
      throw new BadRequestException('Exam session is not in progress');
    }

    const answerValue = Array.isArray(dto.value) ? dto.value.join(',') : dto.value;
    const questionObjectId = new Types.ObjectId(dto.questionId);

    const existingResponse = session.responses?.find(
      (r) => r.questionId.toString() === dto.questionId,
    );

    if (existingResponse) {
      await this.sessionModel
        .updateOne(
          {
            _id: sessionId,
            studentId: new Types.ObjectId(userId),
            status: SessionStatus.STARTED,
            'responses.questionId': questionObjectId,
          },
          { $set: { 'responses.$.selectedOption': answerValue, updatedAt: new Date() } },
        )
        .exec();
    } else {
      await this.sessionModel
        .updateOne(
          {
            _id: sessionId,
            studentId: new Types.ObjectId(userId),
            status: SessionStatus.STARTED,
            'responses.questionId': { $ne: questionObjectId },
          },
          {
            $push: { responses: { questionId: questionObjectId, selectedOption: answerValue } },
            $set: { updatedAt: new Date() },
          },
        )
        .exec();
    }
  }
}
