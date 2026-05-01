import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Subject, SubjectDocument } from './schemas/subject.schema.js';
import { SubjectBundle, SubjectBundleDocument } from './schemas/subject-bundle.schema.js';
import {
  SubjectCode,
  SubjectCodeDocument,
  CodeStatus as SubjectCodeStatus,
} from '../activation-codes/schemas/subject-code.schema.js';
import { User, UserDocument } from '../users/schemas/user.schema.js';
import { Lesson, LessonDocument } from '../lessons/schemas/lesson.schema.js';
import {
  LessonProgress,
  LessonProgressDocument,
} from '../lesson-progress/schemas/lesson-progress.schema.js';
import { CreateSubjectDto } from './dto/create-subject.dto.js';
import { UpdateSubjectDto } from './dto/update-subject.dto.js';
import { CreateBundleDto } from './dto/create-bundle.dto.js';
import { UpdateBundleDto } from './dto/update-bundle.dto.js';
import { ListSubjectsQueryDto } from './dto/list-subjects-query.dto.js';

@Injectable()
export class SubjectsService {
  constructor(
    @InjectModel(Subject.name) private readonly subjectModel: Model<SubjectDocument>,
    @InjectModel(SubjectBundle.name) private readonly bundleModel: Model<SubjectBundleDocument>,
    @InjectModel(SubjectCode.name) private readonly subjectCodeModel: Model<SubjectCodeDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Lesson.name) private readonly lessonModel: Model<LessonDocument>,
    @InjectModel(LessonProgress.name)
    private readonly lessonProgressModel: Model<LessonProgressDocument>,
  ) {}

  private async computeProgressPercents(
    userId: string,
    subjectIds: string[],
  ): Promise<Map<string, number>> {
    const result = new Map<string, number>();
    if (subjectIds.length === 0) return result;

    const validIds = subjectIds
      .filter((id) => Types.ObjectId.isValid(id))
      .map((id) => new Types.ObjectId(id));
    if (validIds.length === 0) return result;

    const userObjectId = new Types.ObjectId(userId);

    const [totals, completedAgg] = await Promise.all([
      this.lessonModel.aggregate<{ _id: Types.ObjectId; total: number }>([
        { $match: { subjectId: { $in: validIds }, isActive: true } },
        { $group: { _id: '$subjectId', total: { $sum: 1 } } },
      ]),
      this.lessonProgressModel.aggregate<{
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
      ]),
    ]);

    const completedMap = new Map<string, number>();
    for (const row of completedAgg) {
      completedMap.set(row._id.toString(), row.completed);
    }
    for (const row of totals) {
      const id = row._id.toString();
      const completed = completedMap.get(id) ?? 0;
      result.set(id, row.total > 0 ? completed / row.total : 0);
    }
    for (const id of subjectIds) {
      if (!result.has(id)) result.set(id, 0);
    }
    return result;
  }

  async createSubject(dto: CreateSubjectDto, userId: string): Promise<SubjectDocument> {
    const subject = new this.subjectModel({
      ...dto,
      createdBy: new Types.ObjectId(userId),
    });
    return subject.save();
  }

  async create(dto: CreateSubjectDto, userId: string): Promise<SubjectDocument> {
    return this.createSubject(dto, userId);
  }

  async findAllSubjects(
    query: ListSubjectsQueryDto,
    role?: string,
    userId?: string,
  ): Promise<{ data: any[]; total: number }> {
    const filter: Record<string, any> = {};
    if (query.category) {
      filter.category = query.category;
    }
    if (query.search) {
      filter.title = { $regex: query.search, $options: 'i' };
    }
    if (role === 'student') {
      filter.isActive = true;
      if (userId) {
        const student = await this.userModel.findById(userId).select('level').lean().exec();
        if (student?.level) {
          filter.level = student.level;
        }
      }
    } else if (query.level) {
      filter.level = query.level;
    }

    const skip = (query.page - 1) * query.limit;

    const [subjects, total] = await Promise.all([
      this.subjectModel
        .find(filter)
        .skip(skip)
        .limit(query.limit)
        .sort({ createdAt: -1 })
        .lean()
        .exec(),
      this.subjectModel.countDocuments(filter).exec(),
    ]);

    if (role === 'student' && userId) {
      const subjectIds = subjects.map((s) => s._id.toString());
      const [unlockedIds, progressMap] = await Promise.all([
        this.getUnlockedSubjectIds(userId),
        this.computeProgressPercents(userId, subjectIds),
      ]);
      const data = subjects.map((subject) => {
        const id = subject._id.toString();
        return {
          ...subject,
          isUnlocked: unlockedIds.has(id),
          progressPercent: progressMap.get(id) ?? 0,
        };
      });
      return { data, total };
    }

    const data = subjects.map((subject) => ({
      ...subject,
      isUnlocked: false,
      progressPercent: 0,
    }));
    return { data, total };
  }

  async getUnlockedSubjectIds(userId: string): Promise<Set<string>> {
    const sId = new Types.ObjectId(userId);

    const directCodes = await this.subjectCodeModel
      .find({
        activatedBy: sId,
        status: SubjectCodeStatus.USED,
        subjectId: { $exists: true },
      })
      .select('subjectId')
      .lean()
      .exec();

    const unlockedIds = new Set<string>();
    for (const code of directCodes) {
      if (code.subjectId) unlockedIds.add(code.subjectId.toString());
    }

    const bundleCodes = await this.subjectCodeModel
      .find({
        activatedBy: sId,
        status: SubjectCodeStatus.USED,
        bundleId: { $exists: true },
      })
      .select('bundleId')
      .lean()
      .exec();

    if (bundleCodes.length > 0) {
      const bundleIds = bundleCodes.map((bc) => bc.bundleId!).filter(Boolean);
      const bundles = await this.bundleModel
        .find({
          _id: { $in: bundleIds },
        })
        .select('subjects')
        .lean()
        .exec();

      for (const bundle of bundles) {
        for (const subId of bundle.subjects) {
          unlockedIds.add(subId.toString());
        }
      }
    }

    return unlockedIds;
  }

  async findSubjectById(id: string): Promise<SubjectDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid subject id');
    }
    const subject = await this.subjectModel.findById(id).exec();
    if (!subject) throw new NotFoundException('Subject not found');
    return subject;
  }

  async findSubjectByIdForUser(id: string, role?: string, userId?: string): Promise<any> {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid subject id');
    }
    const subject = await this.subjectModel.findById(id).lean().exec();
    if (!subject) throw new NotFoundException('Subject not found');

    if (role === 'student' && userId) {
      const student = await this.userModel.findById(userId).select('level').lean().exec();
      if (student?.level && subject.level && subject.level !== student.level) {
        throw new NotFoundException('Subject not found');
      }
    }

    let isUnlocked = false;
    let progressPercent = 0;
    if (role === 'student' && userId) {
      const [unlockedIds, progressMap] = await Promise.all([
        this.getUnlockedSubjectIds(userId),
        this.computeProgressPercents(userId, [subject._id.toString()]),
      ]);
      isUnlocked = unlockedIds.has(subject._id.toString());
      progressPercent = progressMap.get(subject._id.toString()) ?? 0;
    } else if (role !== 'student') {
      isUnlocked = true;
    }
    return { ...subject, isUnlocked, progressPercent };
  }

  async updateSubject(id: string, dto: UpdateSubjectDto): Promise<SubjectDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid subject id');
    }
    const subject = await this.subjectModel.findByIdAndUpdate(id, dto, { new: true }).exec();
    if (!subject) throw new NotFoundException('Subject not found');
    return subject;
  }

  async deleteSubject(id: string): Promise<void> {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid subject id');
    }
    const subject = await this.subjectModel.findByIdAndUpdate(id, { isActive: false }).exec();
    if (!subject) throw new NotFoundException('Subject not found');
  }

  async createBundle(dto: CreateBundleDto): Promise<SubjectBundleDocument> {
    // Validate subjects exist
    const subjects = await this.subjectModel.find({ _id: { $in: dto.subjectIds } }).exec();
    if (subjects.length !== dto.subjectIds.length) {
      throw new BadRequestException('One or more subjects not found');
    }

    const bundle = new this.bundleModel({
      name: dto.name,
      subjects: dto.subjectIds.map((id) => new Types.ObjectId(id)),
    });
    return bundle.save();
  }

  async findAllBundles(): Promise<SubjectBundleDocument[]> {
    return this.bundleModel.find({ isActive: true }).populate('subjects').exec();
  }

  async updateBundle(id: string, dto: UpdateBundleDto): Promise<SubjectBundleDocument> {
    if (dto.subjectIds) {
      const subjects = await this.subjectModel.find({ _id: { $in: dto.subjectIds } }).exec();
      if (subjects.length !== dto.subjectIds.length) {
        throw new BadRequestException('One or more subjects not found');
      }
    }

    const updateData: any = { ...dto };
    if (dto.subjectIds) {
      updateData.subjects = dto.subjectIds.map((subId) => new Types.ObjectId(subId));
      delete updateData.subjectIds;
    }

    const bundle = await this.bundleModel.findByIdAndUpdate(id, updateData, { new: true }).exec();
    if (!bundle) throw new NotFoundException('Bundle not found');
    return bundle;
  }

  async deleteBundle(id: string): Promise<void> {
    const bundle = await this.bundleModel.findByIdAndUpdate(id, { isActive: false }).exec();
    if (!bundle) throw new NotFoundException('Bundle not found');
  }
}
