import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Exam, ExamSchema } from './schemas/exam.schema.js';
import { ExamSession, ExamSessionSchema } from './schemas/exam-session.schema.js';
import { ExamScore, ExamScoreSchema } from './schemas/exam-score.schema.js';
import { ExamsService } from './exams.service.js';
import { ExamsController } from './exams.controller.js';
import { ActivationCodesModule } from '../activation-codes/activation-codes.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Exam.name, schema: ExamSchema },
      { name: ExamSession.name, schema: ExamSessionSchema },
      { name: ExamScore.name, schema: ExamScoreSchema },
    ]),
    forwardRef(() => ActivationCodesModule),
  ],
  controllers: [ExamsController],
  providers: [ExamsService],
  exports: [ExamsService],
})
export class ExamsModule {}
