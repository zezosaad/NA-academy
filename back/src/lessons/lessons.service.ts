import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Lesson, LessonDocument } from './schemas/lesson.schema.js';
import { Subject, SubjectDocument } from '../subjects/schemas/subject.schema.js';
import {
  LessonProgress,
  LessonProgressDocument,
} from '../lesson-progress/schemas/lesson-progress.schema.js';
import { CreateLessonDto } from './dto/create-lesson.dto.js';
import { UpdateLessonDto } from './dto/update-lesson.dto.js';
import { SubjectsService } from '../subjects/subjects.service.js';

@Injectable()
export class LessonsService {
  constructor(
    @InjectModel(Lesson.name) private readonly lessonModel: Model<LessonDocument>,
    @InjectModel(Subject.name) private readonly subjectModel: Model<SubjectDocument>,
    @InjectModel(LessonProgress.name)
    private readonly lessonProgressModel: Model<LessonProgressDocument>,
    private readonly subjectsService: SubjectsService,
  ) {}

  private async getFirstLessonId(subjectId: string): Promise<string | null> {
    const firstLesson = await this.lessonModel
      .findOne({ subjectId: new Types.ObjectId(subjectId), isActive: true })
      .sort({ order: 1, createdAt: 1 })
      .select('_id')
      .lean()
      .exec();

    return firstLesson?._id?.toString() ?? null;
  }

  async hasUnlockedSubjectAccess(userId: string, subjectId: string): Promise<boolean> {
    const unlockedIds = await this.subjectsService.getUnlockedSubjectIds(userId);
    return unlockedIds.has(subjectId);
  }

  async canAccessLessonContent(
    userId: string,
    lesson: Pick<Lesson, '_id' | 'subjectId'>,
  ): Promise<boolean> {
    const subjectId = lesson.subjectId.toString();
    const hasSubjectAccess = await this.hasUnlockedSubjectAccess(userId, subjectId);
    if (hasSubjectAccess) {
      return true;
    }

    const firstLessonId = await this.getFirstLessonId(subjectId);
    return firstLessonId == lesson._id.toString();
  }

  async canAccessMediaContent(userId: string, subjectId: string, mediaId: string): Promise<boolean> {
    const hasSubjectAccess = await this.hasUnlockedSubjectAccess(userId, subjectId);
    if (hasSubjectAccess) {
      return true;
    }

    const lesson = await this.lessonModel
      .findOne({
        subjectId: new Types.ObjectId(subjectId),
        mediaId: new Types.ObjectId(mediaId),
        isActive: true,
      })
      .sort({ order: 1, createdAt: 1 })
      .select('_id subjectId')
      .lean()
      .exec();

    if (!lesson) {
      return false;
    }

    return this.canAccessLessonContent(userId, lesson);
  }

  async create(
    subjectId: string,
    dto: CreateLessonDto,
    userId: string,
  ): Promise<LessonDocument> {
    const subject = await this.subjectModel.findById(subjectId).exec();
    if (!subject) throw new NotFoundException('Subject not found');

    const lesson = new this.lessonModel({
      subjectId: new Types.ObjectId(subjectId),
      title: dto.title,
      description: dto.description,
      order: dto.order ?? 0,
      mediaId: dto.mediaId ? new Types.ObjectId(dto.mediaId) : undefined,
      createdBy: new Types.ObjectId(userId),
    });
    return lesson.save();
  }

  async findBySubject(subjectId: string, userId?: string): Promise<any[]> {
    const lessons = await this.lessonModel
      .find({ subjectId: new Types.ObjectId(subjectId), isActive: true })
      .sort({ order: 1, createdAt: 1 })
      .lean()
      .exec();

    if (!userId) {
      return lessons.map((l) => ({ ...l, isCompleted: false, status: 'active' }));
    }

    const [completedRows, hasUnlockedAccess] = await Promise.all([
      this.lessonProgressModel
        .find({
          userId: new Types.ObjectId(userId),
          subjectId: new Types.ObjectId(subjectId),
          isCompleted: true,
        })
        .select('lessonId')
        .lean()
        .exec(),
      this.hasUnlockedSubjectAccess(userId, subjectId),
    ]);
    const completedSet = new Set(
      completedRows.map((r) => r.lessonId.toString()),
    );
    const firstAccessibleLessonId = lessons.length > 0 ? lessons[0]._id.toString() : null;

    return lessons.map((l) => ({
      ...l,
      isCompleted: completedSet.has(l._id.toString()),
      status: completedSet.has(l._id.toString())
        ? 'done'
        : hasUnlockedAccess || l._id.toString() == firstAccessibleLessonId
          ? 'active'
          : 'locked',
    }));
  }

  async findById(id: string, userId?: string): Promise<any> {
    const lesson = await this.lessonModel.findById(id).lean().exec();
    if (!lesson) throw new NotFoundException('Lesson not found');
    if (!userId) return { ...lesson, isCompleted: false };

    const progress = await this.lessonProgressModel
      .findOne({
        userId: new Types.ObjectId(userId),
        lessonId: new Types.ObjectId(id),
      })
      .select('isCompleted watchedSeconds durationSeconds')
      .lean()
      .exec();
    const canAccess = await this.canAccessLessonContent(userId, lesson);
    const isCompleted = progress?.isCompleted ?? false;
    return {
      ...lesson,
      isCompleted,
      status: isCompleted ? 'done' : canAccess ? 'active' : 'locked',
      watchedSeconds: progress?.watchedSeconds ?? 0,
      durationSeconds: progress?.durationSeconds ?? 0,
    };
  }

  async update(id: string, dto: UpdateLessonDto): Promise<LessonDocument> {
    const update: Record<string, unknown> = { ...dto };
    if (dto.mediaId !== undefined) {
      update.mediaId = dto.mediaId ? new Types.ObjectId(dto.mediaId) : null;
    }
    const lesson = await this.lessonModel.findByIdAndUpdate(id, update, { new: true }).exec();
    if (!lesson) throw new NotFoundException('Lesson not found');
    return lesson;
  }

  async remove(id: string): Promise<void> {
    const lesson = await this.lessonModel.findByIdAndUpdate(id, { isActive: false }).exec();
    if (!lesson) throw new NotFoundException('Lesson not found');
  }
}
