import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  LessonProgress,
  LessonProgressSchema,
} from './schemas/lesson-progress.schema.js';
import { Lesson, LessonSchema } from '../lessons/schemas/lesson.schema.js';
import { LessonsModule } from '../lessons/lessons.module.js';
import { LessonProgressService } from './lesson-progress.service.js';
import { LessonProgressController } from './lesson-progress.controller.js';
import { SubjectsModule } from '../subjects/subjects.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: LessonProgress.name, schema: LessonProgressSchema },
      { name: Lesson.name, schema: LessonSchema },
    ]),
    LessonsModule,
    SubjectsModule,
  ],
  controllers: [LessonProgressController],
  providers: [LessonProgressService],
  exports: [LessonProgressService],
})
export class LessonProgressModule {}
