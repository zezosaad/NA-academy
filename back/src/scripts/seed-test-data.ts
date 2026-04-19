import { NestFactory } from '@nestjs/core';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersModule } from '../users/users.module.js';
import { UsersService } from '../users/users.service.js';
import { SubjectsModule } from '../subjects/subjects.module.js';
import { SubjectsService } from '../subjects/subjects.service.js';
import { ExamsModule } from '../exams/exams.module.js';
import { ExamsService } from '../exams/exams.service.js';
import { UserRole } from '../users/schemas/user.schema.js';
import configuration from '../config/configuration.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        uri: configService.get<string>('mongodb.uri'),
      }),
      inject: [ConfigService],
    }),
    UsersModule,
    SubjectsModule,
    ExamsModule,
  ],
})
class TestSeedModule {}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(TestSeedModule);
  
  const usersService = app.get(UsersService);
  const subjectsService = app.get(SubjectsService);
  const examsService = app.get(ExamsService);

  console.log('--- Seeding Test Data ---');

  // 1. Create some students
  const students = [
    { name: 'Ahmed Mohamed', email: 'ahmed@example.com', password: 'password123', role: UserRole.STUDENT },
    { name: 'Sara Ahmed', email: 'sara@example.com', password: 'password123', role: UserRole.STUDENT },
    { name: 'Zaid Khalid', email: 'zaid@example.com', password: 'password123', role: UserRole.STUDENT },
  ];

  for (const s of students) {
    try {
      const exists = await usersService.findByEmail(s.email);
      if (!exists) {
        await usersService.createUser(s);
        console.log(`Created student: ${s.name}`);
      } else {
        console.log(`Student ${s.name} already exists`);
      }
    } catch (e) {
      console.error(`Failed to create student ${s.name}:`, e);
    }
  }

  // Ensure a valid creator account exists for subject/exam ownership
  const systemAdminEmail = 'system@na-academy.local';
  let systemUser = await usersService.findByEmail(systemAdminEmail);
  if (!systemUser) {
    systemUser = await usersService.createAdminUser({
      name: 'System Seeder',
      email: systemAdminEmail,
      password: 'password123',
    });
    console.log('Created system admin user for seeded content');
  }
  const systemUserId = systemUser._id.toString();

  // 2. Create some subjects
  const subjects = [
    { title: 'Mathematics - Algebra', category: 'Math', description: 'Advanced algebra course' },
    { title: 'Physics - Mechanics', category: 'Science', description: 'Basic mechanics principles' },
    { title: 'English Literature', category: 'Languages', description: 'Introduction to Shakespeare' },
  ];

  const createdSubjects = [];
  for (const sub of subjects) {
    try {
      const s = await subjectsService.createSubject(sub as any, systemUserId);
      createdSubjects.push(s);
      console.log(`Created subject: ${sub.title}`);
    } catch (e) {
       console.error(`Failed to create subject ${sub.title}:`, e);
    }
  }

  // 3. Create an exam
  if (createdSubjects.length > 0) {
    try {
      await examsService.createExam({
        title: 'Monthly Math Quiz',
        subjectId: createdSubjects[0]._id.toString(),
        questions: [
          {
            text: 'What is 2 + 2?',
            options: [
              { label: 'A', text: '3' },
              { label: 'B', text: '4' },
              { label: 'C', text: '5' },
              { label: 'D', text: '6' }
            ],
            correctOption: 'B',
            timeLimitSeconds: 30,
            order: 0
          }
        ]
      } as any, systemUserId);
      console.log('Created test exam');
    } catch (e) {
      console.log('Exam might already exist or failed');
    }
  }

  console.log('--- Seeding Completed ---');
  await app.close();
  process.exit(0);
}

bootstrap().catch(err => {
  console.error('Failed to seed test data:', err);
  process.exit(1);
});
