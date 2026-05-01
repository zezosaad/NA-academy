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
import { AudienceResolverService } from './audience-resolver.service.js';
import { PushTokensModule } from '../push-tokens/push-tokens.module.js';
import { UsersModule } from '../users/users.module.js';
import { User, UserSchema } from '../users/schemas/user.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
      { name: NotificationRecipient.name, schema: NotificationRecipientSchema },
      { name: User.name, schema: UserSchema },
    ]),
    PushTokensModule,
    UsersModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, FcmService, AudienceResolverService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
