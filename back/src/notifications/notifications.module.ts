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
import { RetentionService } from './retention.service.js';
import { PushTokensModule } from '../push-tokens/push-tokens.module.js';
import { UsersModule } from '../users/users.module.js';
import { User, UserSchema } from '../users/schemas/user.schema.js';
import { Subject, SubjectSchema } from '../subjects/schemas/subject.schema.js';
import { PushToken, PushTokenSchema } from '../push-tokens/schemas/push-token.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
      { name: NotificationRecipient.name, schema: NotificationRecipientSchema },
      { name: User.name, schema: UserSchema },
      { name: Subject.name, schema: SubjectSchema },
      { name: PushToken.name, schema: PushTokenSchema },
    ]),
    PushTokensModule,
    UsersModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, FcmService, AudienceResolverService, RetentionService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
