import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Subject, SubjectSchema } from './schemas/subject.schema.js';
import { SubjectBundle, SubjectBundleSchema } from './schemas/subject-bundle.schema.js';
import { SubjectCode, SubjectCodeSchema } from '../activation-codes/schemas/subject-code.schema.js';
import { SubjectsService } from './subjects.service.js';
import { SubjectsController } from './subjects.controller.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Subject.name, schema: SubjectSchema },
      { name: SubjectBundle.name, schema: SubjectBundleSchema },
      { name: SubjectCode.name, schema: SubjectCodeSchema },
    ]),
  ],
  controllers: [SubjectsController],
  providers: [SubjectsService],
  exports: [SubjectsService],
})
export class SubjectsModule {}
