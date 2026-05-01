import {
  Injectable,
  Logger,
  ForbiddenException,
  UnprocessableEntityException,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, PipelineStage, Types } from 'mongoose';
import { createHash } from 'crypto';
import { Notification, NotificationDocument } from './schemas/notification.schema.js';
import {
  NotificationRecipient,
  NotificationRecipientDocument,
  RecipientState,
} from './schemas/notification-recipient.schema.js';
import { CreateNotificationDto } from './dto/create-notification.dto.js';
import {
  NotificationResponseDto,
  NotificationStatsDto,
  AudienceResponseDto,
  NotificationListResponseDto,
} from './dto/notification-response.dto.js';
import {
  InboxItemDto,
  InboxResponseDto,
  NotificationDetailResponseDto,
} from './dto/recipient-state.dto.js';
import { FcmService } from './fcm.service.js';
import { AudienceResolverService } from './audience-resolver.service.js';
import { PushTokensService } from '../push-tokens/push-tokens.service.js';
import { UserRole } from '../users/schemas/user.schema.js';
import { UsersService } from '../users/users.service.js';
import { NotificationListQueryDto } from './dto/notification-list-query.dto.js';

type InboxNotificationAggregate = {
  notificationId: Types.ObjectId;
  title: string;
  body: string;
  data?: Record<string, string>;
  createdAt: Date;
  readAt?: Date;
  senderName?: string;
};

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectModel(Notification.name)
    private readonly notificationModel: Model<NotificationDocument>,
    @InjectModel(NotificationRecipient.name)
    private readonly recipientModel: Model<NotificationRecipientDocument>,
    private readonly fcmService: FcmService,
    private readonly audienceResolver: AudienceResolverService,
    private readonly pushTokensService: PushTokensService,
    private readonly usersService: UsersService,
  ) {}

  async send(
    senderId: string,
    senderRole: UserRole,
    dto: CreateNotificationDto,
    idempotencyKey: string,
  ): Promise<{ notification: NotificationDocument; recipientCount: number }> {
    // 1. Idempotency check
    const senderObjectId = new Types.ObjectId(senderId);
    const existing = await this.notificationModel
      .findOne({ senderId: senderObjectId, idempotencyKey })
      .exec();
    if (existing) {
      this.logger.log(`Idempotent replay for key=${idempotencyKey}`);
      return { notification: existing, recipientCount: existing.audience.resolvedRecipientCount };
    }

    // 2. RBAC: teacher can only send to 'subject'
    if (senderRole === UserRole.TEACHER && dto.audience.kind !== 'subject') {
      throw new ForbiddenException('audience-forbidden');
    }

    // 3. Resolve audience
    let resolvedUserIds: Types.ObjectId[];
    if (dto.audience.kind === 'all') {
      resolvedUserIds = await this.audienceResolver.resolveAll();
    } else if (dto.audience.kind === 'user-list') {
      resolvedUserIds = await this.audienceResolver.resolveUserList(dto.audience.userIds ?? []);
    } else {
      resolvedUserIds = await this.audienceResolver.resolveSubject(
        dto.audience.subjectId!,
        senderId,
        senderRole,
      );
    }

    if (resolvedUserIds.length === 0) {
      throw new UnprocessableEntityException('audience-empty');
    }

    // 4. Insert Notification document
    const notificationDoc = new this.notificationModel({
      title: dto.title,
      body: dto.body,
      data: dto.data,
      senderId: senderObjectId,
      senderRole,
      audience: {
        kind: dto.audience.kind,
        userIds: dto.audience.userIds?.map((id) => new Types.ObjectId(id)),
        subjectId: dto.audience.subjectId ? new Types.ObjectId(dto.audience.subjectId) : undefined,
        resolvedUserIds,
        resolvedRecipientCount: resolvedUserIds.length,
      },
      idempotencyKey,
      stats: {
        total: resolvedUserIds.length,
        delivered: 0,
        failed: 0,
        read: 0,
      },
    });
    const savedNotification = await notificationDoc.save();
    const notificationId = savedNotification._id;

    // 5. Bulk-insert NotificationRecipient rows (state=pending)
    const recipientDocs = resolvedUserIds.map((userId) => ({
      notificationId,
      userId,
      state: RecipientState.PENDING,
    }));
    await this.recipientModel.insertMany(recipientDocs, { ordered: false });

    // 6. Look up active push tokens
    const activeTokenDocs = await this.pushTokensService.findActiveForUserIds(resolvedUserIds);
    const tokenUserMap = new Map<string, Types.ObjectId>();
    for (const td of activeTokenDocs) {
      tokenUserMap.set(td.token, td.userId);
    }

    // Mark recipients with no token as failed
    const usersWithToken = new Set(activeTokenDocs.map((td) => td.userId.toHexString()));
    const noTokenUserIds = resolvedUserIds.filter((uid) => !usersWithToken.has(uid.toHexString()));
    if (noTokenUserIds.length > 0) {
      await this.recipientModel.updateMany(
        { notificationId, userId: { $in: noTokenUserIds } },
        { state: RecipientState.FAILED, failureReason: 'no-active-token' },
      );
    }

    let deliveredCount = 0;
    let failedCount = noTokenUserIds.length;

    // 7. FCM send
    if (activeTokenDocs.length > 0) {
      const tokens = activeTokenDocs.map((td) => td.token);
      const dataPayload: Record<string, string> = {};
      dataPayload.notificationId = notificationId.toHexString();
      if (dto.data) {
        for (const [k, v] of Object.entries(dto.data)) {
          dataPayload[k] = v;
        }
      }
      const result = await this.fcmService.sendBatch(tokens, {
        title: dto.title,
        body: dto.body,
        data: dataPayload,
      });

      const recipientUpdates = [] as Array<{
        updateOne: {
          filter: { notificationId: Types.ObjectId; userId: Types.ObjectId };
          update: {
            state: RecipientState;
            deliveredAt?: Date;
            failureReason?: string;
          };
        };
      }>;

      for (const tokenResult of result.perTokenResults) {
        const userId = tokenUserMap.get(tokenResult.token);
        if (!userId) continue;

        if (tokenResult.success) {
          recipientUpdates.push({
            updateOne: {
              filter: { notificationId, userId },
              update: { state: RecipientState.DELIVERED, deliveredAt: new Date() },
            },
          });
          deliveredCount++;
        } else {
          recipientUpdates.push({
            updateOne: {
              filter: { notificationId, userId },
              update: {
                state: RecipientState.FAILED,
                failureReason: tokenResult.error?.code ?? 'unknown',
              },
            },
          });
          failedCount++;
        }
      }

      if (recipientUpdates.length > 0) {
        await this.recipientModel.bulkWrite(recipientUpdates, { ordered: false });
      }
    }

    // 8. Recompute stats and persist
    const updatedNotification = await this.notificationModel
      .findByIdAndUpdate(
        notificationId,
        {
          'stats.delivered': deliveredCount,
          'stats.failed': failedCount,
        },
        { new: true },
      )
      .exec();

    // 9. Audit log
    const titleHash = createHash('sha256').update(dto.title).digest('hex');
    const bodyHash = createHash('sha256').update(dto.body).digest('hex');
    this.logger.log(
      JSON.stringify({
        event: 'notifications.send',
        senderId,
        audienceDescriptor: dto.audience,
        titleHash,
        bodyHash,
        idempotencyKey,
        resolvedRecipientCount: resolvedUserIds.length,
      }),
    );

    return {
      notification: updatedNotification ?? savedNotification,
      recipientCount: resolvedUserIds.length,
    };
  }

  async toResponseDto(notification: NotificationDocument): Promise<NotificationResponseDto> {
    const statsDto = new NotificationStatsDto();
    statsDto.total = notification.stats.total;
    statsDto.delivered = notification.stats.delivered;
    statsDto.failed = notification.stats.failed;
    statsDto.read = notification.stats.read;

    const audienceDto = new AudienceResponseDto();
    audienceDto.kind = notification.audience.kind as AudienceResponseDto['kind'];
    audienceDto.userIds = notification.audience.userIds?.map((id) => id.toHexString());
    audienceDto.subjectId = notification.audience.subjectId?.toHexString();
    audienceDto.resolvedRecipientCount = notification.audience.resolvedRecipientCount;

    const sender = await this.usersService.findById(notification.senderId.toHexString());

    const dto = new NotificationResponseDto();
    dto.id = notification._id.toHexString();
    dto.title = notification.title;
    dto.body = notification.body;
    dto.data = notification.data ? Object.fromEntries(notification.data) : undefined;
    dto.senderId = notification.senderId.toHexString();
    dto.senderName = sender?.name ?? '';
    dto.senderRole = notification.senderRole;
    dto.audience = audienceDto;
    dto.stats = statsDto;
    dto.createdAt = notification.createdAt.toISOString();
    return dto;
  }

  async listHistory(
    currentUserId: string,
    currentUserRole: UserRole,
    query: NotificationListQueryDto,
  ): Promise<NotificationListResponseDto> {
    const filter: Record<string, unknown> = {};
    const limit = query.limit ?? 20;

    if (currentUserRole === UserRole.TEACHER) {
      filter.senderId = new Types.ObjectId(currentUserId);
    }

    if (query.audienceKind) {
      filter['audience.kind'] = query.audienceKind;
    }

    if (query.subjectId) {
      filter['audience.subjectId'] = new Types.ObjectId(query.subjectId);
    }

    if (query.before) {
      const [beforeIso, beforeId] = query.before.split('|');
      const beforeDate = new Date(beforeIso);
      if (!Number.isNaN(beforeDate.getTime()) && Types.ObjectId.isValid(beforeId)) {
        filter.$or = [
          { createdAt: { $lt: beforeDate } },
          { createdAt: beforeDate, _id: { $lt: new Types.ObjectId(beforeId) } },
        ];
      }
    }

    if (query.q) {
      filter.$text = { $search: query.q };
    }

    const notifications = await this.notificationModel
      .find(filter)
      .sort(
        query.q
          ? ({ score: { $meta: 'textScore' }, createdAt: -1, _id: -1 } as const)
          : { createdAt: -1, _id: -1 },
      )
      .limit(limit + 1)
      .exec();

    const hasMore = notifications.length > limit;
    const items = hasMore ? notifications.slice(0, limit) : notifications;
    const responseItems = await Promise.all(items.map((item) => this.toResponseDto(item)));

    const response = new NotificationListResponseDto();
    response.items = responseItems;
    response.nextCursor = hasMore
      ? `${items[items.length - 1].createdAt.toISOString()}|${items[items.length - 1]._id.toHexString()}`
      : undefined;
    return response;
  }

  async getDetail(
    id: string,
    currentUserId: string,
    currentUserRole: UserRole,
  ): Promise<NotificationDetailResponseDto> {
    const recipientPageLimit = 100;
    const notification = await this.notificationModel.findById(id).exec();
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    if (
      currentUserRole === UserRole.TEACHER &&
      notification.senderId.toHexString() !== currentUserId
    ) {
      throw new ForbiddenException('audience-forbidden');
    }

    const base = await this.toResponseDto(notification);
    const detail = Object.assign(new NotificationDetailResponseDto(), base);

    const retentionCutoff = new Date(notification.createdAt.getTime() + 365 * 24 * 60 * 60 * 1000);
    if (retentionCutoff < new Date()) {
      detail.recipientsArchived = true;
      detail.recipientsArchivedAt = retentionCutoff.toISOString();
      return detail;
    }

    const recipientsTotal = await this.recipientModel.countDocuments({ notificationId: notification._id }).exec();

    const recipients = await this.recipientModel
      .find({ notificationId: notification._id })
      .sort({ createdAt: 1, _id: 1 })
      .limit(recipientPageLimit)
      .lean()
      .exec();

    const userIds = recipients.map((recipient) => recipient.userId).filter((userId, index, array) => index === array.findIndex((candidate) => candidate.equals(userId)));
    const users = userIds.length
      ? await this.usersService.findManyByIds(userIds.map((userId) => userId.toString()))
      : [];
    const userNameMap = new Map(
      users
        .filter((user): user is NonNullable<typeof user> => Boolean(user))
        .map((user) => [user._id.toString(), user.name]),
    );

    detail.recipients = recipients.map((recipient) => ({
      userId: recipient.userId.toString(),
      userName: userNameMap.get(recipient.userId.toString()) ?? recipient.userId.toString(),
      state: recipient.state,
      failureReason: recipient.failureReason,
      deliveredAt: recipient.deliveredAt?.toISOString(),
      readAt: recipient.readAt?.toISOString(),
    }));
    detail.recipientsTotal = recipientsTotal;
    detail.recipientsLimit = recipientPageLimit;
    detail.recipientsNextCursor = recipientsTotal > recipients.length && recipients.length > 0
      ? `${recipients[recipients.length - 1].createdAt.toISOString()}|${recipients[recipients.length - 1]._id.toString()}`
      : undefined;

    return detail;
  }

  async getInbox(userId: string, limit: number, before?: string): Promise<InboxResponseDto> {
    const userObjectId = new Types.ObjectId(userId);
    const beforeDate = before ? new Date(before) : undefined;
    const pipeline: PipelineStage[] = [
      { $match: { userId: userObjectId } },
      {
        $lookup: {
          from: 'notifications',
          localField: 'notificationId',
          foreignField: '_id',
          as: 'notification',
        },
      },
      { $unwind: '$notification' },
      {
        $lookup: {
          from: 'users',
          localField: 'notification.senderId',
          foreignField: '_id',
          as: 'sender',
        },
      },
      {
        $unwind: {
          path: '$sender',
          preserveNullAndEmptyArrays: true,
        },
      },
    ];

    if (beforeDate) {
      pipeline.push({ $match: { 'notification.createdAt': { $lt: beforeDate } } });
    }

    pipeline.push(
      { $sort: { 'notification.createdAt': -1 } },
      { $limit: limit + 1 },
      {
        $project: {
          _id: 0,
          notificationId: '$notification._id',
          title: '$notification.title',
          body: '$notification.body',
          data: '$notification.data',
          createdAt: '$notification.createdAt',
          readAt: '$readAt',
          senderName: '$sender.name',
        },
      },
    );

    const aggregatedItems = await this.recipientModel
      .aggregate<InboxNotificationAggregate>(pipeline)
      .exec();

    const hasMore = aggregatedItems.length > limit;
    const items = hasMore ? aggregatedItems.slice(0, limit) : aggregatedItems;

    const unreadCount = await this.recipientModel
      .countDocuments({ userId: userObjectId, readAt: null })
      .exec();

    let nextCursor: string | undefined;
    if (hasMore && items.length > 0) {
      nextCursor = items[items.length - 1].createdAt.toISOString();
    }

    const inboxItems: InboxItemDto[] = items.map((item) => {
      const dto = new InboxItemDto();
      dto.id = item.notificationId.toHexString();
      dto.title = item.title;
      dto.body = item.body;
      dto.data = item.data;
      dto.createdAt = item.createdAt.toISOString();
      dto.readAt = item.readAt?.toISOString();
      dto.senderName = item.senderName;
      return dto;
    });

    const response = new InboxResponseDto();
    response.items = inboxItems;
    response.nextCursor = nextCursor;
    response.unreadCount = unreadCount;
    return response;
  }

  async markRead(userId: string, notificationId: string): Promise<void> {
    const userObjectId = new Types.ObjectId(userId);
    const notifObjectId = new Types.ObjectId(notificationId);

    const recipient = await this.recipientModel
      .findOne({ notificationId: notifObjectId, userId: userObjectId })
      .exec();

    if (!recipient) {
      throw new NotFoundException('Notification not found in your inbox');
    }

    if (recipient.readAt) {
      return;
    }

    recipient.readAt = new Date();
    await recipient.save();

    await this._recomputeReadStats(notifObjectId);
  }

  async markAllRead(userId: string): Promise<{ markedRead: number }> {
    const userObjectId = new Types.ObjectId(userId);
    const affectedNotificationIds = await this.recipientModel
      .find({ userId: userObjectId, readAt: null })
      .distinct('notificationId')
      .exec();

    const affected = await this.recipientModel
      .updateMany({ userId: userObjectId, readAt: null }, { readAt: new Date() })
      .exec();

    if (affected.modifiedCount > 0) {
      await Promise.all(
        affectedNotificationIds.map((notifId) =>
          this._recomputeReadStats(new Types.ObjectId(notifId)),
        ),
      );
    }

    return { markedRead: affected.modifiedCount };
  }

  private async _recomputeReadStats(notificationId: Types.ObjectId): Promise<void> {
    const readCount = await this.recipientModel
      .countDocuments({ notificationId, readAt: { $ne: null } })
      .exec();

    await this.notificationModel
      .updateOne({ _id: notificationId }, { 'stats.read': readCount })
      .exec();
  }
}
