import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { SubjectCode, SubjectCodeDocument, CodeStatus as SubjectCodeStatus } from '../schemas/subject-code.schema.js';
import { SubjectBundle, SubjectBundleDocument } from '../../subjects/schemas/subject-bundle.schema.js';

@Injectable()
export class AccessCheckHelper {
  constructor(
    @InjectModel(SubjectCode.name) private readonly subjectCodeModel: Model<SubjectCodeDocument>,
    @InjectModel(SubjectBundle.name) private readonly bundleModel: Model<SubjectBundleDocument>,
  ) {}

  /**
   * Verified if the student has access to the subjectId via individual code OR bundle code
   */
  async hasSubjectAccess(studentId: string, subjectId: string): Promise<boolean> {
    const sId = new Types.ObjectId(studentId);
    const subId = new Types.ObjectId(subjectId);

    // 1. Direct subject access via USED subject code
    const directAccess = await this.subjectCodeModel.exists({
      activatedBy: sId,
      status: SubjectCodeStatus.USED,
      subjectId: subId,
    }).exec();

    if (directAccess) return true;

    // 2. Access via bundle code
    const bundleCodes = await this.subjectCodeModel.find({
      activatedBy: sId,
      status: SubjectCodeStatus.USED,
      bundleId: { $exists: true }
    }).exec();

    if (bundleCodes.length === 0) return false;

    const bundleIds = bundleCodes.map(bc => bc.bundleId).filter(id => id !== undefined) as Types.ObjectId[];
    
    // Check if any of these bundles contain the subject
    const bundleWithSubject = await this.bundleModel.exists({
      _id: { $in: bundleIds },
      subjects: subId,
    }).exec();

    return !!bundleWithSubject;
  }
}
