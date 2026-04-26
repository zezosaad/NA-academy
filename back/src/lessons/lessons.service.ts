import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Lesson, LessonDocument } from './schemas/lesson.schema.js';
import { Subject, SubjectDocument } from '../subjects/schemas/subject.schema.js';
import { CreateLessonDto } from './dto/create-lesson.dto.js';
import { UpdateLessonDto } from './dto/update-lesson.dto.js';

@Injectable()
export class LessonsService {
  constructor(
    @InjectModel(Lesson.name) private readonly lessonModel: Model<LessonDocument>,
    @InjectModel(Subject.name) private readonly subjectModel: Model<SubjectDocument>,
  ) {}

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

  async findBySubject(subjectId: string): Promise<LessonDocument[]> {
    return this.lessonModel
      .find({ subjectId: new Types.ObjectId(subjectId), isActive: true })
      .sort({ order: 1, createdAt: 1 })
      .exec();
  }

  async findById(id: string): Promise<LessonDocument> {
    const lesson = await this.lessonModel.findById(id).exec();
    if (!lesson) throw new NotFoundException('Lesson not found');
    return lesson;
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
