import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SubjectCode, SubjectCodeSchema } from './schemas/subject-code.schema.js';
import { ExamCode, ExamCodeSchema } from './schemas/exam-code.schema.js';
import {
  ActivationRateLimit,
  ActivationRateLimitSchema,
} from './schemas/activation-rate-limit.schema.js';
import { ActivationCodesService } from './activation-codes.service.js';
import { ActivationCodesController } from './activation-codes.controller.js';
import { AccessCheckHelper } from './helpers/access-check.helper.js';
import { SubjectsModule } from '../subjects/subjects.module.js';
import { ExamsModule } from '../exams/exams.module.js';

import { SubjectBundle, SubjectBundleSchema } from '../subjects/schemas/subject-bundle.schema.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SubjectCode.name, schema: SubjectCodeSchema },
      { name: ExamCode.name, schema: ExamCodeSchema },
      { name: ActivationRateLimit.name, schema: ActivationRateLimitSchema },
      { name: SubjectBundle.name, schema: SubjectBundleSchema },
    ]),
    SubjectsModule,
    forwardRef(() => ExamsModule),
  ],
  controllers: [ActivationCodesController],
  providers: [ActivationCodesService, AccessCheckHelper],
  exports: [ActivationCodesService, AccessCheckHelper, MongooseModule],
})
export class ActivationCodesModule {}
