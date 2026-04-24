import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { SecurityFlag, SecurityFlagDocument, ActionTaken } from './schemas/security-flag.schema.js';
import { ReportFlagDto, ReviewFlagDto, ListFlagsQueryDto } from './dto/security.dto.js';
import { AuthService } from '../auth/auth.service.js';

@Injectable()
export class SecurityService {
  private readonly logger = new Logger(SecurityService.name);

  constructor(
    @InjectModel(SecurityFlag.name) private readonly flagModel: Model<SecurityFlagDocument>,
    private readonly authService: AuthService,
  ) {}

  async reportFlag(
    studentId: string,
    deviceId: string,
    dto: ReportFlagDto,
  ): Promise<SecurityFlagDocument> {
    const flag = new this.flagModel({
      studentId: new Types.ObjectId(studentId),
      deviceId,
      flagType: dto.flagType,
      metadata: dto.metadata,
      actionTaken: ActionTaken.SESSION_TERMINATED,
    });
    await flag.save();

    // Terminate sessions proactively
    await this.authService.deleteAllSessions(studentId);
    this.logger.warn(
      `Security flag ${dto.flagType} triggered for user ${studentId}. Sessions terminated.`,
    );

    return flag;
  }

  async listFlags(query: ListFlagsQueryDto): Promise<SecurityFlagDocument[]> {
    const filter: Record<string, any> = {};
    if (query.studentId) filter.studentId = new Types.ObjectId(query.studentId);
    if (query.flagType) filter.flagType = query.flagType;

    return this.flagModel
      .find(filter)
      .sort({ createdAt: -1 })
      .populate('studentId', 'name email')
      .populate('reviewedBy', 'name')
      .exec();
  }

  async reviewFlag(
    flagId: string,
    reviewerId: string,
    dto: ReviewFlagDto,
  ): Promise<SecurityFlagDocument> {
    const flag = await this.flagModel
      .findByIdAndUpdate(
        flagId,
        {
          actionTaken: dto.actionTaken,
          reviewedBy: new Types.ObjectId(reviewerId),
          reviewedAt: new Date(),
        },
        { new: true },
      )
      .exec();

    if (!flag) throw new NotFoundException('Flag not found');
    return flag;
  }
}
