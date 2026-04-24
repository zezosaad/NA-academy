import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as stream from 'stream';
import exceljs from 'exceljs';
import * as fastCsv from '@fast-csv/format';
import { Response } from 'express';

import {
  SubjectCode,
  SubjectCodeDocument,
  CodeStatus as SubjectCodeStatus,
} from './schemas/subject-code.schema.js';
import {
  ExamCode,
  ExamCodeDocument,
  CodeStatus as ExamCodeStatus,
  ExamUsageType,
} from './schemas/exam-code.schema.js';
import { generateBatch, generateBatchId, formatCode } from './utils/code-generator.js';
import { GenerateSubjectCodesDto } from './dto/generate-subject-codes.dto.js';
import { GenerateExamCodesDto } from './dto/generate-exam-codes.dto.js';
import { ListCodesQueryDto } from './dto/list-codes-query.dto.js';
import { ExportFormat } from './dto/batch-export-query.dto.js';

import { SubjectsService } from '../subjects/subjects.service.js';
import { ExamsService } from '../exams/exams.service.js';

@Injectable()
export class ActivationCodesService {
  private readonly logger = new Logger(ActivationCodesService.name);

  constructor(
    @InjectModel(SubjectCode.name) private readonly subjectCodeModel: Model<SubjectCodeDocument>,
    @InjectModel(ExamCode.name) private readonly examCodeModel: Model<ExamCodeDocument>,
    private readonly subjectsService: SubjectsService,
    private readonly examsService: ExamsService,
  ) {}

  async generateSubjectCodes(dto: GenerateSubjectCodesDto) {
    if (dto.subjectId && dto.bundleId) {
      throw new BadRequestException('Provide either subjectId or bundleId, not both');
    }
    if (!dto.subjectId && !dto.bundleId) {
      throw new BadRequestException('Provide either subjectId or bundleId');
    }

    let linkedName = '';
    if (dto.subjectId) {
      const subject = await this.subjectsService.findSubjectById(dto.subjectId);
      linkedName = subject.title;
    } else if (dto.bundleId) {
      // Validate bundle exists - if subjectsService handles this or we can just fetch it
      // Let's assume there's a findBundleById if we implemented it, or just ignore display name for bundle context if not implemented
      linkedName = 'Subject Bundle';
    }

    const batchId = generateBatchId();
    let generatedCount = 0;

    // Retry loop for collisions
    while (generatedCount < dto.quantity) {
      const needed = dto.quantity - generatedCount;
      const rawCodes = generateBatch(needed);

      const docs = rawCodes.map((c) => ({
        code: c,
        subjectId: dto.subjectId ? new Types.ObjectId(dto.subjectId) : undefined,
        bundleId: dto.bundleId ? new Types.ObjectId(dto.bundleId) : undefined,
        status: SubjectCodeStatus.AVAILABLE,
        batchId,
      }));

      try {
        await this.subjectCodeModel.insertMany(docs, { ordered: false });
        generatedCount += needed;
      } catch (error: any) {
        if (error.code === 11000) {
          // Bulk write error with collisions. Count successful inserts.
          const inserted = error.insertedDocs?.length || 0;
          generatedCount += inserted;
        } else {
          throw error;
        }
      }
    }

    this.logger.log(`Generated ${dto.quantity} subject codes for batch ${batchId}`);
    return {
      batchId,
      count: dto.quantity,
      type: 'subject',
      linkedTo: { id: dto.subjectId || dto.bundleId, name: linkedName },
    };
  }

  async generateExamCodes(dto: GenerateExamCodesDto) {
    const exam = await this.examsService.findExamById(dto.examId);

    if (dto.usageType === ExamUsageType.MULTI && !dto.maxUses) {
      throw new BadRequestException('maxUses is required for multi-use codes');
    }

    const batchId = generateBatchId();
    let generatedCount = 0;

    while (generatedCount < dto.quantity) {
      const needed = dto.quantity - generatedCount;
      const rawCodes = generateBatch(needed);

      const docs = rawCodes.map((c) => ({
        code: c,
        examId: new Types.ObjectId(dto.examId),
        usageType: dto.usageType,
        maxUses: dto.usageType === ExamUsageType.MULTI ? dto.maxUses : undefined,
        remainingUses: dto.usageType === ExamUsageType.MULTI ? dto.maxUses : undefined,
        timeLimitMinutes: dto.timeLimitMinutes,
        status: ExamCodeStatus.AVAILABLE,
        batchId,
      }));

      try {
        await this.examCodeModel.insertMany(docs, { ordered: false });
        generatedCount += needed;
      } catch (error: any) {
        if (error.code === 11000) {
          const inserted = error.insertedDocs?.length || 0;
          generatedCount += inserted;
        } else {
          throw error;
        }
      }
    }

    this.logger.log(`Generated ${dto.quantity} exam codes for batch ${batchId}`);
    return {
      batchId,
      count: dto.quantity,
      type: 'exam',
      linkedTo: { id: exam._id, name: exam.title },
    };
  }

  async hasExamAccess(studentId: string, examId: string, hardwareId?: string): Promise<boolean> {
    if (!Types.ObjectId.isValid(studentId) || !Types.ObjectId.isValid(examId)) {
      return false;
    }

    const filter: Record<string, any> = {
      examId: new Types.ObjectId(examId),
      activatedBy: new Types.ObjectId(studentId),
      status: { $in: [ExamCodeStatus.USED, ExamCodeStatus.AVAILABLE] },
    };

    if (hardwareId) {
      filter.activationDeviceId = hardwareId;
    }

    const examCode = await this.examCodeModel.findOne(filter).exec();
    return !!examCode;
  }

  async activateCode(codeStr: string, studentId: string, hardwareId: string) {
    const sId = new Types.ObjectId(studentId);

    // Look for SubjectCode
    let codeDoc: any = await this.subjectCodeModel.findOne({ code: codeStr }).exec();
    let isSubject = true;

    // Look for ExamCode if not found
    if (!codeDoc) {
      isSubject = false;
      codeDoc = await this.examCodeModel.findOne({ code: codeStr }).exec();
    }

    if (!codeDoc) {
      throw new BadRequestException('Invalid activation code');
    }

    if (codeDoc.status === SubjectCodeStatus.EXPIRED) {
      throw new BadRequestException('This activation code has expired');
    }

    if (codeDoc.status === SubjectCodeStatus.USED && isSubject) {
      throw new BadRequestException('Code has already been used');
    }

    if (codeDoc.activatedBy && codeDoc.activatedBy.toString() !== studentId) {
      throw new BadRequestException('Code has already been used by another user');
    }

    if (codeDoc.activationDeviceId && codeDoc.activationDeviceId !== hardwareId) {
      throw new BadRequestException('Device mismatch for this code activation');
    }

    if (isSubject) {
      const subjectDoc = codeDoc as SubjectCodeDocument;
      subjectDoc.status = SubjectCodeStatus.USED;
      subjectDoc.activatedBy = sId;
      subjectDoc.activatedAt = new Date();
      subjectDoc.activationDeviceId = hardwareId;
      await subjectDoc.save();

      let targetItems: any = [];
      if (subjectDoc.subjectId) {
        const sub = await this.subjectsService.findSubjectById(subjectDoc.subjectId.toString());
        targetItems = [sub];
      } else if (subjectDoc.bundleId) {
        // Find bundle subjects
        const bundles = await this.subjectsService.findAllBundles();
        const targetedBundle = bundles.find(
          (b) => b._id.toString() === subjectDoc.bundleId?.toString(),
        );
        if (targetedBundle && targetedBundle.subjects) {
          targetItems = targetedBundle.subjects;
        }
      }

      return {
        type: 'subject',
        activatedSubjects: targetItems.map((s: any) => ({
          id: s._id,
          title: s.title || 'Subject',
        })),
        message: 'Subject unlocked successfully',
      };
    } else {
      const examDoc = codeDoc;
      if (examDoc.usageType === ExamUsageType.SINGLE && examDoc.status === ExamCodeStatus.USED) {
        throw new BadRequestException('Exam code already used');
      }

      if (examDoc.usageType === ExamUsageType.MULTI) {
        if (examDoc.remainingUses === 0) {
          throw new BadRequestException('Exam code usage limit reached');
        }
        examDoc.remainingUses -= 1;
      }

      examDoc.status = ExamCodeStatus.USED; // Can stay used for SINGLE, irrelevant for MULTI basically, or mark USED on 0 remaining
      if (
        examDoc.usageType === ExamUsageType.MULTI &&
        examDoc.remainingUses &&
        examDoc.remainingUses > 0
      ) {
        examDoc.status = ExamCodeStatus.AVAILABLE;
      }

      if (!examDoc.firstActivatedAt) {
        examDoc.firstActivatedAt = new Date();
      }

      examDoc.activatedBy = sId;
      examDoc.activationDeviceId = hardwareId;

      await examDoc.save();

      return {
        type: 'exam',
        examId: examDoc.examId,
        message: 'Exam unlocked successfully',
        timeLimitMinutes: examDoc.timeLimitMinutes,
      };
    }
  }

  async findByBatch(batchId: string, query: ListCodesQueryDto) {
    // Try to find in subject codes first
    let isSubject = true;
    let total = await this.subjectCodeModel.countDocuments({ batchId }).exec();

    if (total === 0) {
      isSubject = false;
      total = await this.examCodeModel.countDocuments({ batchId }).exec();
      if (total === 0) {
        throw new NotFoundException('Batch not found');
      }
    }

    const modelToUse = (isSubject ? this.subjectCodeModel : this.examCodeModel) as Model<any>;
    const filter: Record<string, any> = { batchId };
    if (query.status) {
      filter.status = query.status;
    }

    const skip = (query.page - 1) * query.limit;

    const [data, filteredTotal] = await Promise.all([
      modelToUse.find(filter).skip(skip).limit(query.limit).sort({ createdAt: -1 }).exec(),
      modelToUse.countDocuments(filter).exec(),
    ]);

    return { data, total: filteredTotal, isSubject };
  }

  async revokeCode(id: string) {
    let updated: any = await this.subjectCodeModel
      .findByIdAndUpdate(id, { status: SubjectCodeStatus.EXPIRED }, { new: true })
      .exec();
    if (!updated) {
      updated = await this.examCodeModel
        .findByIdAndUpdate(id, { status: ExamCodeStatus.EXPIRED }, { new: true })
        .exec();
    }
    if (!updated) {
      throw new NotFoundException('Code not found');
    }
    return updated;
  }

  async revokeBatch(batchId: string) {
    const subjectResult = await this.subjectCodeModel
      .updateMany(
        { batchId, status: SubjectCodeStatus.AVAILABLE },
        { $set: { status: SubjectCodeStatus.EXPIRED } },
      )
      .exec();

    const examResult = await this.examCodeModel
      .updateMany(
        { batchId, status: ExamCodeStatus.AVAILABLE },
        { $set: { status: ExamCodeStatus.EXPIRED } },
      )
      .exec();

    return {
      revampedSubjectCodes: subjectResult.modifiedCount,
      revokedExamCodes: examResult.modifiedCount,
    };
  }

  // T051 Export Functionality
  async exportBatch(batchId: string, format: ExportFormat, res: Response) {
    const { data: subjectCodes } = await this.findByBatch(batchId, { page: 1, limit: 1000000 });
    const isSubject = subjectCodes.length > 0 && subjectCodes[0] instanceof this.subjectCodeModel;

    const codes = subjectCodes;

    const rows = codes.map((c: any) => ({
      Code: formatCode(c.code),
      Entity: c.subjectId || c.bundleId || c.examId,
      Status: c.status,
      GeneratedAt: c.createdAt.toISOString(),
    }));

    if (format === ExportFormat.XLSX) {
      res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      res.setHeader('Content-Disposition', `attachment; filename=batch_${batchId}.xlsx`);

      const options = { stream: res, useStyles: true, useSharedStrings: true };
      const workbook = new exceljs.stream.xlsx.WorkbookWriter(options);
      const worksheet = workbook.addWorksheet('Codes');

      worksheet.columns = [
        { header: 'Code', key: 'Code', width: 25 },
        { header: 'Entity ID', key: 'Entity', width: 30 },
        { header: 'Status', key: 'Status', width: 15 },
        { header: 'Generated At', key: 'GeneratedAt', width: 25 },
      ];

      for (const row of rows) {
        worksheet.addRow(row).commit();
      }

      worksheet.commit();
      await workbook.commit();
    } else if (format === ExportFormat.CSV) {
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename=batch_${batchId}.csv`);

      const csvStream = fastCsv.format({ headers: true });
      csvStream.pipe(res);
      for (const row of rows) {
        csvStream.write(row);
      }
      csvStream.end();
    }
  }
}
