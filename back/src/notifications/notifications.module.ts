import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Notification, NotificationSchema } from './schemas/notification.schema.js';
import {
  NotificationRecipient,
  NotificationRecipientSchema,
} from './schemas/notification-recipient.schema.js';
import { NotificationsService } from './notifications.service.js';
import { NotificationsController } from './notifications.controller.js';
import { FcmService } from './fcm.service.js';
import { PushTokensModule } from '../push-tokens/push-tokens.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
      { name: NotificationRecipient.name, schema: NotificationRecipientSchema },
    ]),
    PushTokensModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, FcmService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
