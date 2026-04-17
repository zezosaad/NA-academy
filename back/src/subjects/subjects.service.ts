import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Subject, SubjectDocument } from './schemas/subject.schema.js';
import { SubjectBundle, SubjectBundleDocument } from './schemas/subject-bundle.schema.js';
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
  ) {}

  async createSubject(dto: CreateSubjectDto, userId: string): Promise<SubjectDocument> {
    const subject = new this.subjectModel({
      ...dto,
      createdBy: new Types.ObjectId(userId),
    });
    return subject.save();
  }

  async findAllSubjects(query: ListSubjectsQueryDto, role?: string): Promise<{ data: SubjectDocument[], total: number }> {
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

    const [data, total] = await Promise.all([
      this.subjectModel.find(filter).skip(skip).limit(query.limit).sort({ createdAt: -1 }).exec(),
      this.subjectModel.countDocuments(filter).exec(),
    ]);

    return { data, total };
  }

  async findSubjectById(id: string): Promise<SubjectDocument> {
    const subject = await this.subjectModel.findById(id).exec();
    if (!subject) throw new NotFoundException('Subject not found');
    return subject;
  }

  async updateSubject(id: string, dto: UpdateSubjectDto): Promise<SubjectDocument> {
    const subject = await this.subjectModel.findByIdAndUpdate(id, dto, { new: true }).exec();
    if (!subject) throw new NotFoundException('Subject not found');
    return subject;
  }

  async deleteSubject(id: string): Promise<void> {
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
      subjects: dto.subjectIds.map(id => new Types.ObjectId(id)),
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
      updateData.subjects = dto.subjectIds.map(subId => new Types.ObjectId(subId));
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
