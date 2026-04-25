import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Conversation, ConversationSchema } from './schemas/conversation.schema.js';
import { Message, MessageSchema } from './schemas/message.schema.js';
import { User, UserSchema } from '../users/schemas/user.schema.js';
import { Subject, SubjectSchema } from '../subjects/schemas/subject.schema.js';
import { SubjectCode, SubjectCodeSchema } from '../activation-codes/schemas/subject-code.schema.js';
import { SubjectBundle, SubjectBundleSchema } from '../subjects/schemas/subject-bundle.schema.js';
import { ChatGateway } from './chat.gateway.js';
import { ChatService } from './chat.service.js';
import { ChatController } from './chat.controller.js';
import { ActivationCodesModule } from '../activation-codes/activation-codes.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Conversation.name, schema: ConversationSchema },
      { name: Message.name, schema: MessageSchema },
      { name: User.name, schema: UserSchema },
      { name: Subject.name, schema: SubjectSchema },
      { name: SubjectCode.name, schema: SubjectCodeSchema },
      { name: SubjectBundle.name, schema: SubjectBundleSchema },
    ]),
    ActivationCodesModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('jwt.secret'),
        signOptions: {
          expiresIn: (configService.get<string>('jwt.accessExpiration') || '15m') as any,
        },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [ChatGateway, ChatService],
  controllers: [ChatController],
})
export class ChatModule {}
