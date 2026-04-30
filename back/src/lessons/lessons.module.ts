import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Lesson, LessonSchema } from './schemas/lesson.schema.js';
import { Subject, SubjectSchema } from '../subjects/schemas/subject.schema.js';
import {
  LessonProgress,
  LessonProgressSchema,
} from '../lesson-progress/schemas/lesson-progress.schema.js';
import { LessonsService } from './lessons.service.js';
import { LessonsController } from './lessons.controller.js';
import { SubjectsModule } from '../subjects/subjects.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Lesson.name, schema: LessonSchema },
      { name: Subject.name, schema: SubjectSchema },
      { name: LessonProgress.name, schema: LessonProgressSchema },
    ]),
    SubjectsModule,
  ],
  controllers: [LessonsController],
  providers: [LessonsService],
  exports: [LessonsService],
})
export class LessonsModule {}
