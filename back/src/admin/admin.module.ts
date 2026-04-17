import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminService } from './admin.service.js';
import { AdminController } from './admin.controller.js';
import { Session, SessionSchema } from '../auth/schemas/session.schema.js';
import { ExamSession, ExamSessionSchema } from '../exams/schemas/exam-session.schema.js';
import { SubjectCode, SubjectCodeSchema } from '../activation-codes/schemas/subject-code.schema.js';
import { SecurityFlag, SecurityFlagSchema } from '../security/schemas/security-flag.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Session.name, schema: SessionSchema },
      { name: ExamSession.name, schema: ExamSessionSchema },
      { name: SubjectCode.name, schema: SubjectCodeSchema },
      { name: SecurityFlag.name, schema: SecurityFlagSchema },
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
