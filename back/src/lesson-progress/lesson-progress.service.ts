import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  LessonProgress,
  LessonProgressDocument,
} from './schemas/lesson-progress.schema.js';
import { Lesson, LessonDocument } from '../lessons/schemas/lesson.schema.js';
import { SubjectsService } from '../subjects/subjects.service.js';
import { UpdateProgressDto } from './dto/update-progress.dto.js';

export const LESSON_COMPLETION_THRESHOLD = 0.9;

export interface SubjectProgressSummary {
  completed: number;
  total: number;
  percent: number;
}

@Injectable()
export class LessonProgressService {
  constructor(
    @InjectModel(LessonProgress.name)
    private readonly progressModel: Model<LessonProgressDocument>,
    @InjectModel(Lesson.name)
    private readonly lessonModel: Model<LessonDocument>,
    private readonly subjectsService: SubjectsService,
  ) {}

  private async assertUnlocked(
    subjectId: string,
    role: string,
    userId: string,
  ): Promise<void> {
    if (role !== 'student') return;
    const unlocked = await this.subjectsService.getUnlockedSubjectIds(userId);
    if (!unlocked.has(subjectId)) {
      throw new ForbiddenException('Subject is locked. Activate a code first.');
    }
  }

  async updateProgress(
    userId: string,
    lessonId: string,
    role: string,
    dto: UpdateProgressDto,
  ): Promise<{ isCompleted: boolean; watchedSeconds: number; durationSeconds: number }> {
    if (!Types.ObjectId.isValid(lessonId)) {
      throw new BadRequestException('Invalid lesson id');
    }

    const lesson = await this.lessonModel.findById(lessonId).lean().exec();
    if (!lesson || !lesson.isActive) {
      throw new NotFoundException('Lesson not found');
    }

    await this.assertUnlocked(lesson.subjectId.toString(), role, userId);

    const existing = await this.progressModel
      .findOne({
        userId: new Types.ObjectId(userId),
        lessonId: new Types.ObjectId(lessonId),
      })
      .lean()
      .exec();

    const wasCompleted = existing?.isCompleted ?? false;
    const ratio =
      dto.durationSeconds > 0 ? dto.watchedSeconds / dto.durationSeconds : 0;
    const justCompleted = !wasCompleted && ratio >= LESSON_COMPLETION_THRESHOLD;

    const set: Record<string, unknown> = {
      durationSeconds: dto.durationSeconds,
      subjectId: lesson.subjectId,
      lastWatchedAt: new Date(),
    };
    if (justCompleted) {
      set.isCompleted = true;
      set.completedAt = new Date();
    }

    const updated = await this.progressModel
      .findOneAndUpdate(
        {
          userId: new Types.ObjectId(userId),
          lessonId: new Types.ObjectId(lessonId),
        },
        {
          $max: { watchedSeconds: dto.watchedSeconds },
          $set: set,
          $setOnInsert: {
            userId: new Types.ObjectId(userId),
            lessonId: new Types.ObjectId(lessonId),
          },
        },
        { upsert: true, new: true },
      )
      .lean()
      .exec();

    return {
      isCompleted: updated!.isCompleted,
      watchedSeconds: updated!.watchedSeconds,
      durationSeconds: updated!.durationSeconds,
    };
  }

  async markComplete(
    userId: string,
    lessonId: string,
    role: string,
  ): Promise<{ isCompleted: true }> {
    if (!Types.ObjectId.isValid(lessonId)) {
      throw new BadRequestException('Invalid lesson id');
    }

    const lesson = await this.lessonModel.findById(lessonId).lean().exec();
    if (!lesson || !lesson.isActive) {
      throw new NotFoundException('Lesson not found');
    }

    await this.assertUnlocked(lesson.subjectId.toString(), role, userId);

    const now = new Date();
    await this.progressModel
      .updateOne(
        {
          userId: new Types.ObjectId(userId),
          lessonId: new Types.ObjectId(lessonId),
        },
        {
          $set: {
            isCompleted: true,
            completedAt: now,
            lastWatchedAt: now,
            subjectId: lesson.subjectId,
          },
          $setOnInsert: {
            userId: new Types.ObjectId(userId),
            lessonId: new Types.ObjectId(lessonId),
            watchedSeconds: 0,
            durationSeconds: 0,
          },
        },
        { upsert: true },
      )
      .exec();

    return { isCompleted: true };
  }

  async getSubjectProgress(
    userId: string,
    subjectId: string,
  ): Promise<SubjectProgressSummary> {
    if (!Types.ObjectId.isValid(subjectId)) {
      return { completed: 0, total: 0, percent: 0 };
    }
    const subjectObjectId = new Types.ObjectId(subjectId);
    const userObjectId = new Types.ObjectId(userId);

    const [total, completed] = await Promise.all([
      this.lessonModel
        .countDocuments({ subjectId: subjectObjectId, isActive: true })
        .exec(),
      this.progressModel
        .countDocuments({
          userId: userObjectId,
          subjectId: subjectObjectId,
          isCompleted: true,
        })
        .exec(),
    ]);

    return {
      completed,
      total,
      percent: total > 0 ? completed / total : 0,
    };
  }

  async getSubjectProgressBatch(
    userId: string,
    subjectIds: string[],
  ): Promise<Map<string, SubjectProgressSummary>> {
    const result = new Map<string, SubjectProgressSummary>();
    if (subjectIds.length === 0) return result;

    const validIds = subjectIds
      .filter((id) => Types.ObjectId.isValid(id))
      .map((id) => new Types.ObjectId(id));
    if (validIds.length === 0) return result;

    const userObjectId = new Types.ObjectId(userId);

    const totals = await this.lessonModel.aggregate<{
      _id: Types.ObjectId;
      total: number;
    }>([
      { $match: { subjectId: { $in: validIds }, isActive: true } },
      { $group: { _id: '$subjectId', total: { $sum: 1 } } },
    ]);

    const completedAgg = await this.progressModel.aggregate<{
      _id: Types.ObjectId;
      completed: number;
    }>([
      {
        $match: {
          userId: userObjectId,
          subjectId: { $in: validIds },
          isCompleted: true,
        },
      },
      { $group: { _id: '$subjectId', completed: { $sum: 1 } } },
    ]);

    const completedMap = new Map<string, number>();
    for (const row of completedAgg) {
      completedMap.set(row._id.toString(), row.completed);
    }

    for (const row of totals) {
      const subjectId = row._id.toString();
      const completed = completedMap.get(subjectId) ?? 0;
      result.set(subjectId, {
        completed,
        total: row.total,
        percent: row.total > 0 ? completed / row.total : 0,
      });
    }

    for (const id of subjectIds) {
      if (!result.has(id)) {
        result.set(id, { completed: 0, total: 0, percent: 0 });
      }
    }

    return result;
  }

  async getCompletedLessonIds(
    userId: string,
    subjectId: string,
  ): Promise<Set<string>> {
    if (!Types.ObjectId.isValid(subjectId)) return new Set();
    const rows = await this.progressModel
      .find({
        userId: new Types.ObjectId(userId),
        subjectId: new Types.ObjectId(subjectId),
        isCompleted: true,
      })
      .select('lessonId')
      .lean()
      .exec();
    return new Set(rows.map((r) => r.lessonId.toString()));
  }
}
