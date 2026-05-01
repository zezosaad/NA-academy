import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ConfigService } from '@nestjs/config';

import { Notification, NotificationDocument } from './schemas/notification.schema.js';
import {
  NotificationRecipient,
  NotificationRecipientDocument,
} from './schemas/notification-recipient.schema.js';
import { PushToken, PushTokenDocument } from '../push-tokens/schemas/push-token.schema.js';

@Injectable()
export class RetentionService {
  private readonly logger = new Logger(RetentionService.name);

  constructor(
    @InjectModel(Notification.name)
    private readonly notificationModel: Model<NotificationDocument>,
    @InjectModel(NotificationRecipient.name)
    private readonly recipientModel: Model<NotificationRecipientDocument>,
    @InjectModel(PushToken.name)
    private readonly pushTokenModel: Model<PushTokenDocument>,
    private readonly configService: ConfigService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async pruneExpiredRecipients(): Promise<void> {
    const nodeEnv = this.configService.get<string>('NODE_ENV');
    const forceRun = this.configService.get<string>('RETENTION_FORCE_RUN') === 'true';
    if (nodeEnv !== 'production' && !forceRun) {
      return;
    }

    const notificationCutoff = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
    const tokenCutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const expiredNotifications = await this.notificationModel
      .aggregate<{
        _id: string;
      }>([{ $match: { createdAt: { $lt: notificationCutoff } } }, { $project: { _id: 1 } }])
      .exec();

    const notificationIds = expiredNotifications.map((notification) => notification._id);
    const deletedRecipients = notificationIds.length
      ? await this.recipientModel.deleteMany({ notificationId: { $in: notificationIds } }).exec()
      : { deletedCount: 0 };

    const deletedTokens = await this.pushTokenModel
      .deleteMany({ tombstonedAt: { $lt: tokenCutoff } })
      .exec();

    this.logger.log(
      `Retention prune completed: recipients=${deletedRecipients.deletedCount ?? 0}, pushTokens=${deletedTokens.deletedCount ?? 0}`,
    );
  }
}
