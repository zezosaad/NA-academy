import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from './schemas/user.schema.js';
import { UsersService } from './users.service.js';
import { UsersController } from './users.controller.js';
import { DevicesModule } from '../devices/devices.module.js';
import { Session, SessionSchema } from '../auth/schemas/session.schema.js';
import { SubjectCode, SubjectCodeSchema } from '../activation-codes/schemas/subject-code.schema.js';
import { ExamCode, ExamCodeSchema } from '../activation-codes/schemas/exam-code.schema.js';
import { WatchTime, WatchTimeSchema } from '../analytics/schemas/watch-time.schema.js';
import { ExamSession, ExamSessionSchema } from '../exams/schemas/exam-session.schema.js';
import { ExamScore, ExamScoreSchema } from '../exams/schemas/exam-score.schema.js';
import { SecurityFlag, SecurityFlagSchema } from '../security/schemas/security-flag.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Session.name, schema: SessionSchema },
      { name: SubjectCode.name, schema: SubjectCodeSchema },
      { name: ExamCode.name, schema: ExamCodeSchema },
      { name: WatchTime.name, schema: WatchTimeSchema },
      { name: ExamSession.name, schema: ExamSessionSchema },
      { name: ExamScore.name, schema: ExamScoreSchema },
      { name: SecurityFlag.name, schema: SecurityFlagSchema },
    ]),
    forwardRef(() => DevicesModule),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
