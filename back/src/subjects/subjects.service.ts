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
  ) {}

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
      const unlockedIds = await this.getUnlockedSubjectIds(userId);
      const data = subjects.map((subject) => ({
        ...subject,
        isUnlocked: unlockedIds.has(subject._id.toString()),
      }));
      return { data, total };
    }

    const data = subjects.map((subject) => ({
      ...subject,
      isUnlocked: false,
    }));
    return { data, total };
  }

  private async getUnlockedSubjectIds(userId: string): Promise<Set<string>> {
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
