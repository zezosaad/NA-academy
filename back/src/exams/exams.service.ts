import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Exam, ExamAccessMode, ExamDocument, Question } from './schemas/exam.schema.js';
import { ExamSession, ExamSessionDocument, SessionStatus } from './schemas/exam-session.schema.js';
import { ExamScore, ExamScoreDocument } from './schemas/exam-score.schema.js';
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

  private normalizeExamPayload(dto: CreateExamDto | UpdateExamDto) {
    const accessMode = this.resolveAccessMode(dto as Partial<Exam>);
    const normalized: Record<string, unknown> = {
      ...dto,
      accessMode,
      hasFreeSection: accessMode === ExamAccessMode.FREE_SECTION,
    };

    if (accessMode !== ExamAccessMode.FREE_SECTION) {
      normalized.freeQuestionCount = undefined;
    }

    if (accessMode === ExamAccessMode.CODE_REQUIRED) {
      normalized.freeAttemptLimit = undefined;
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

  async createExam(dto: CreateExamDto, userId: string): Promise<ExamDocument> {
    this.validateQuestions(dto.questions);

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
      ![ExamAccessMode.FREE_SECTION, ExamAccessMode.FULL_EXAM_FREE_ATTEMPTS].includes(accessMode) ||
      exam.freeAttemptLimit === undefined
    ) {
      return { allowed: false, remainingAttempts: 0, accessMode };
    }

    const previousAttempts = await this.sessionModel
      .countDocuments({
        examId: new Types.ObjectId(examId),
        studentId: new Types.ObjectId(studentId),
        isFreeAttempt: true,
        status: {
          $in: [SessionStatus.COMPLETED, SessionStatus.TIMED_OUT],
        },
      })
      .exec();

    const remainingAttempts = exam.freeAttemptLimit - previousAttempts;
    return {
      allowed: remainingAttempts > 0,
      remainingAttempts: Math.max(0, remainingAttempts),
      accessMode,
    };
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

    const questionPool = this.getQuestionPool(exam, isFreeAttempt);
    const timeLimit = questionPool.reduce((total, q) => total + q.timeLimitSeconds, 0) / 60;

    const session = new this.sessionModel({
      studentId: new Types.ObjectId(studentId),
      examId: exam._id,
      status: SessionStatus.STARTED,
      startedAt: new Date(),
      timeLimitMinutes: Math.floor(timeLimit),
      isFreeAttempt,
    });

    return session.save();
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
        .aggregate<{
          _id: Types.ObjectId;
          count: number;
        }>([
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
        .aggregate<{
          _id: Types.ObjectId;
          scorePercentage: number;
        }>([
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
          freeCompletedCount: number;
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
              freeCompletedCount: {
                $sum: {
                  $cond: [
                    {
                      $and: [
                        { $eq: ['$isFreeAttempt', true] },
                        { $in: ['$status', [SessionStatus.COMPLETED, SessionStatus.TIMED_OUT]] },
                      ],
                    },
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
      const freeCompletedMap = new Map<string, number>();
      const startedMap = new Map<string, number>();
      for (const sc of completedSessionCounts) {
        completedMap.set(sc._id.toString(), sc.completedCount);
        freeCompletedMap.set(sc._id.toString(), sc.freeCompletedCount);
        startedMap.set(sc._id.toString(), sc.startedCount);
      }

      const data = exams.map((exam) => {
        const availableCodes = attemptMap.get(exam._id.toString()) ?? 0;
        const completedAttempts = completedMap.get(exam._id.toString()) ?? 0;
        const completedFreeAttempts = freeCompletedMap.get(exam._id.toString()) ?? 0;
        const hasStartedSession = (startedMap.get(exam._id.toString()) ?? 0) > 0;
        const accessMode = this.resolveAccessMode(exam);
        const isSubjectUnlocked = unlockedSubjectIds.has(exam.subjectId.toString());
        const status = isSubjectUnlocked
          ? completedAttempts > 0
            ? 'completed'
            : 'available'
          : completedAttempts > 0
            ? 'completed'
            : hasStartedSession
              ? 'available'
              : accessMode !== ExamAccessMode.CODE_REQUIRED &&
                  exam.freeAttemptLimit !== undefined &&
                  exam.freeAttemptLimit - completedFreeAttempts > 0
                ? 'available'
                : availableCodes > 0
                  ? 'available'
                  : 'locked';
        return {
          ...exam,
          accessMode,
          isSubjectUnlocked,
          attemptsRemaining: Math.max(0, availableCodes),
          freeAttemptsRemaining:
            accessMode === ExamAccessMode.CODE_REQUIRED || exam.freeAttemptLimit === undefined
              ? 0
              : Math.max(0, exam.freeAttemptLimit - completedFreeAttempts),
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
      attemptsRemaining: 0,
      freeAttemptsRemaining: exam.freeAttemptLimit ?? 0,
      status: 'available' as string,
    }));
    return { data, total };
  }

  async updateExam(id: string, dto: UpdateExamDto): Promise<ExamDocument> {
    if (dto.questions) {
      this.validateQuestions(dto.questions);
    }

    const updateData: any = this.normalizeExamPayload(dto);
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
