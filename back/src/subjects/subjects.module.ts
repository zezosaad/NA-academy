import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Subject, SubjectSchema } from './schemas/subject.schema.js';
import { SubjectBundle, SubjectBundleSchema } from './schemas/subject-bundle.schema.js';
import { SubjectCode, SubjectCodeSchema } from '../activation-codes/schemas/subject-code.schema.js';
import { User, UserSchema } from '../users/schemas/user.schema.js';
import { Lesson, LessonSchema } from '../lessons/schemas/lesson.schema.js';
import {
  LessonProgress,
  LessonProgressSchema,
} from '../lesson-progress/schemas/lesson-progress.schema.js';
import { Exam, ExamSchema } from '../exams/schemas/exam.schema.js';
import { SubjectsService } from './subjects.service.js';
import { SubjectsController } from './subjects.controller.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Subject.name, schema: SubjectSchema },
      { name: SubjectBundle.name, schema: SubjectBundleSchema },
      { name: SubjectCode.name, schema: SubjectCodeSchema },
      { name: User.name, schema: UserSchema },
      { name: Lesson.name, schema: LessonSchema },
      { name: LessonProgress.name, schema: LessonProgressSchema },
      { name: Exam.name, schema: ExamSchema },
    ]),
  ],
  controllers: [SubjectsController],
  providers: [SubjectsService],
  exports: [SubjectsService],
})
export class SubjectsModule {}
