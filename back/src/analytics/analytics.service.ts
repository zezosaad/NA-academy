import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { WatchTime, WatchTimeDocument } from './schemas/watch-time.schema.js';
import { TrackWatchTimeDto } from './dto/analytics.dto.js';
import { MediaService } from '../media/media.service.js';
import { AccessCheckHelper } from '../activation-codes/helpers/access-check.helper.js';
import {
  LessonProgress,
  LessonProgressDocument,
} from '../lesson-progress/schemas/lesson-progress.schema.js';
import { ExamScore, ExamScoreDocument } from '../exams/schemas/exam-score.schema.js';

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(
    @InjectModel(WatchTime.name) private readonly watchTimeModel: Model<WatchTimeDocument>,
    @InjectModel(LessonProgress.name)
    private readonly lessonProgressModel: Model<LessonProgressDocument>,
    @InjectModel(ExamScore.name) private readonly examScoreModel: Model<ExamScoreDocument>,
    private readonly mediaService: MediaService,
    private readonly accessCheckHelper: AccessCheckHelper,
  ) {}

  async trackWatchTime(studentId: string, dto: TrackWatchTimeDto): Promise<void> {
    const asset = await this.mediaService.findAssetById(dto.mediaAssetId);
    if (!asset) throw new NotFoundException('Media asset not found');

    if (!asset.subjectId) {
      throw new ForbiddenException('No subject associated with this content');
    }
    const hasAccess = await this.accessCheckHelper.hasSubjectAccess(
      studentId,
      asset.subjectId.toString(),
    );
    if (!hasAccess) throw new ForbiddenException('No active access to this subject content');

    // Upsert mechanism merging total counts dynamically over identical day limits if necessary,
    // or just appending new records. For simplicity, we just create a new record per heartbeat.
    const watchRecord = new this.watchTimeModel({
      studentId: new Types.ObjectId(studentId),
      mediaAssetId: new Types.ObjectId(dto.mediaAssetId),
      subjectId: asset.subjectId,
      durationSeconds: dto.durationSeconds,
      recordedAt: new Date(),
    });

    await watchRecord.save();
  }

  async getStudentAnalytics(studentId: string) {
    const sId = new Types.ObjectId(studentId);

    // Watch time aggregation
    const watchTimeStats = await this.watchTimeModel
      .aggregate([
        { $match: { studentId: sId } },
        { $group: { _id: '$subjectId', totalWatchTimeSeconds: { $sum: '$durationSeconds' } } },
        {
          $lookup: { from: 'subjects', localField: '_id', foreignField: '_id', as: 'subjectInfo' },
        },
        { $unwind: '$subjectInfo' },
        { $project: { subjectName: '$subjectInfo.title', totalWatchTimeSeconds: 1 } },
      ])
      .exec();

    const lessonsCompleted = await this.lessonProgressModel.countDocuments({
      userId: sId,
      isCompleted: true,
    });

    const totalExamsTaken = await this.examScoreModel.countDocuments({
      studentId: sId,
    });

    const avgScoreResult = await this.examScoreModel
      .aggregate([
        { $match: { studentId: sId } },
        { $group: { _id: null, avg: { $avg: '$scorePercentage' } } },
      ])
      .exec();
    const averageScore =
      avgScoreResult.length > 0 && typeof avgScoreResult[0].avg === 'number'
        ? Number(avgScoreResult[0].avg.toFixed(2))
        : 0;

    const weeklyActivity = await this.computeWeeklyActivity(sId);
    const streakDays = this.computeStreakDays(weeklyActivity);

    return {
      watchTimeStats,
      // New canonical keys
      streakDays,
      lessonsCompleted,
      examsTaken: totalExamsTaken,
      weeklyActivity,
      // Backward compatible keys
      streak: streakDays,
      totalExamsTaken,
      averageScore,
    };
  }

  private async computeWeeklyActivity(studentId: Types.ObjectId): Promise<number[]> {
    const now = new Date();
    const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const start = new Date(dayStart);
    start.setDate(start.getDate() - 6);

    const [lessonEvents, watchEvents, examEvents] = await Promise.all([
      this.lessonProgressModel
        .find(
          {
            userId: studentId,
            isCompleted: true,
            completedAt: { $gte: start },
          },
          { completedAt: 1 },
        )
        .lean()
        .exec(),
      this.watchTimeModel
        .find(
          {
            studentId,
            recordedAt: { $gte: start },
          },
          { recordedAt: 1 },
        )
        .lean()
        .exec(),
      this.examScoreModel
        .find(
          {
            studentId,
            createdAt: { $gte: start },
          },
          { createdAt: 1 },
        )
        .lean()
        .exec(),
    ]);

    const values = Array<number>(7).fill(0);
    const toDayIndex = (date: Date): number => {
      const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
      const diff = Math.floor((d.getTime() - start.getTime()) / (24 * 60 * 60 * 1000));
      return diff;
    };

    for (const item of lessonEvents) {
      if (!item.completedAt) continue;
      const idx = toDayIndex(new Date(item.completedAt));
      if (idx >= 0 && idx < 7) values[idx] += 3;
    }

    for (const item of watchEvents) {
      if (!item.recordedAt) continue;
      const idx = toDayIndex(new Date(item.recordedAt));
      if (idx >= 0 && idx < 7) values[idx] += 1;
    }

    for (const item of examEvents) {
      if (!item.createdAt) continue;
      const idx = toDayIndex(new Date(item.createdAt));
      if (idx >= 0 && idx < 7) values[idx] += 5;
    }

    return values;
  }

  private computeStreakDays(weeklyActivity: number[]): number {
    let streak = 0;
    for (let i = weeklyActivity.length - 1; i >= 0; i -= 1) {
      if (weeklyActivity[i] > 0) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  async getPlatformAnalytics() {
    // Total students, Total content consumed, active codes
    const totalWatchTime = await this.watchTimeModel
      .aggregate([{ $group: { _id: null, totalSeconds: { $sum: '$durationSeconds' } } }])
      .exec();

    return {
      platformSecondsWatched: totalWatchTime.length > 0 ? totalWatchTime[0].totalSeconds : 0,
      activeUsers: 0,
    };
  }
}
