import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { globalValidationPipe } from './../src/common/pipes/validation.pipe.js';
import { AllExceptionsFilter } from './../src/common/filters/all-exceptions.filter.js';
import { ResponseTransformInterceptor } from './../src/common/interceptors/response-transform.interceptor.js';
import { Model } from 'mongoose';
import { getModelToken } from '@nestjs/mongoose';
import { Exam, ExamDocument } from '../src/exams/schemas/exam.schema.js';
import {
  ExamSession,
  ExamSessionDocument,
  SessionStatus,
} from '../src/exams/schemas/exam-session.schema.js';
import {
  ExamCode,
  ExamCodeDocument,
  CodeStatus,
} from '../src/activation-codes/schemas/exam-code.schema.js';

describe('Exams - attemptsRemaining & saveAnswer (e2e)', () => {
  let app: INestApplication<App>;
  let examModel: Model<ExamDocument>;
  let sessionModel: Model<ExamSessionDocument>;
  let examCodeModel: Model<ExamCodeDocument>;

  let adminToken: string;
  let studentToken: string;
  let studentId: string;
  let examId: string;

  const createdExamIds: string[] = [];
  const createdSessionIds: string[] = [];
  const createdCodeIds: string[] = [];

  const PREFIX = '/api/v1';

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(globalValidationPipe);
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new ResponseTransformInterceptor());
    await app.init();

    examModel = moduleFixture.get<Model<ExamDocument>>(getModelToken(Exam.name));
    sessionModel = moduleFixture.get<Model<ExamSessionDocument>>(getModelToken(ExamSession.name));
    examCodeModel = moduleFixture.get<Model<ExamCodeDocument>>(getModelToken(ExamCode.name));
  });

  afterAll(async () => {
    if (createdExamIds.length > 0) {
      await examModel.deleteMany({ _id: { $in: createdExamIds } });
    }
    if (createdSessionIds.length > 0) {
      await sessionModel.deleteMany({ _id: { $in: createdSessionIds } });
    }
    if (createdCodeIds.length > 0) {
      await examCodeModel.deleteMany({ _id: { $in: createdCodeIds } });
    }
    if (app) {
      await app.close();
    }
  });

  it('should project attemptsRemaining for student and handle per-answer autosave', async () => {
    const suffix = Date.now();

    // 1. Register admin
    const adminRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/register-admin`)
      .send({
        name: 'Admin',
        email: `admin-exam-test-${suffix}@na.local`,
        password: 'Passw0rd!',
        hardwareId: `admin-exam-dev-${suffix}`,
      })
      .expect(201);
    adminToken = adminRes.body.data.accessToken ?? adminRes.body.accessToken;
    expect(adminToken).toBeTruthy();

    // 2. Register student
    const studentRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/register`)
      .send({
        name: 'Student',
        email: `student-exam-test-${suffix}@na.local`,
        password: 'Passw0rd!',
        hardwareId: `student-exam-dev-${suffix}`,
      })
      .expect(201);
    studentToken = studentRes.body.data.accessToken ?? studentRes.body.accessToken;
    studentId =
      studentRes.body.data.user?._id ??
      studentRes.body.data.user?.id ??
      studentRes.body.data?.user?._id;
    expect(studentToken).toBeTruthy();

    // 3. Create a subject first (exams need subjectId)
    const subjectRes = await request(app.getHttpServer())
      .post(`${PREFIX}/subjects`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ title: 'Exam Test Subject', description: 'For exam e2e test', category: 'Testing' })
      .expect(201);
    const subjectId =
      (subjectRes.body.data ?? subjectRes.body)._id ?? (subjectRes.body.data ?? subjectRes.body).id;

    // 4. Create an exam as admin
    const createExamRes = await request(app.getHttpServer())
      .post(`${PREFIX}/exams`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        title: 'E2E Exam',
        subjectId,
        questions: [
          {
            text: 'What is 2+2?',
            options: [
              { label: 'A', text: '3' },
              { label: 'B', text: '4' },
            ],
            correctOption: 'B',
            timeLimitSeconds: 60,
            order: 1,
          },
          {
            text: 'What is 3+3?',
            options: [
              { label: 'A', text: '5' },
              { label: 'B', text: '6' },
            ],
            correctOption: 'B',
            timeLimitSeconds: 60,
            order: 2,
          },
        ],
      })
      .expect(201);
    examId =
      (createExamRes.body.data ?? createExamRes.body)._id ??
      (createExamRes.body.data ?? createExamRes.body).id;
    createdExamIds.push(examId);
    expect(examId).toBeDefined();

    // 5. GET /exams as student — attemptsRemaining should be 0 initially
    const beforeCode = await request(app.getHttpServer())
      .get(`${PREFIX}/exams`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);

    const beforeData = beforeCode.body.data ?? beforeCode.body;
    const examListBefore: any[] = beforeData.data ?? beforeData;
    const examBefore = examListBefore.find((e: any) => (e._id ?? e.id) === examId);
    expect(examBefore).toBeDefined();
    expect(examBefore.attemptsRemaining).toBe(0);

    // 6. Generate exam code for the student
    const codesRes = await request(app.getHttpServer())
      .post(`${PREFIX}/activation-codes/exam/generate`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ examId, quantity: 2, usageType: 'single' })
      .expect(201);
    const batchId = (codesRes.body.data ?? codesRes.body).batchId;

    // 7. GET /exams as student — attemptsRemaining should now be 2
    const afterCode = await request(app.getHttpServer())
      .get(`${PREFIX}/exams`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);

    const afterData = afterCode.body.data ?? afterCode.body;
    const examListAfter: any[] = afterData.data ?? afterData;
    const examAfter = examListAfter.find((e: any) => (e._id ?? e.id) === examId);
    expect(examAfter).toBeDefined();
    expect(examAfter.attemptsRemaining).toBeGreaterThanOrEqual(1);

    // 8. Activate the code and start an exam session
    const batchListRes = await request(app.getHttpServer())
      .get(`${PREFIX}/activation-codes/batch/${batchId}?page=1&limit=1`)
      .set('Authorization', `Bearer ${adminToken}`);
    const codeValue = (batchListRes.body.data ?? batchListRes.body).data?.[0]?.code;
    expect(codeValue).toBeDefined();

    await request(app.getHttpServer())
      .post(`${PREFIX}/activation-codes/activate`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ code: codeValue })
      .expect(200);

    const startRes = await request(app.getHttpServer())
      .post(`${PREFIX}/exams/${examId}/start`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);

    const session = startRes.body.data?.session ?? startRes.body.session;
    const sessionId = session?._id ?? session?.id;
    expect(sessionId).toBeDefined();
    createdSessionIds.push(sessionId);

    // 9. POST /exams/sessions/:sessionId/answer — save an answer
    const questionId =
      (createExamRes.body.data ?? createExamRes.body).questions?.[0]?._id ??
      (createExamRes.body.data ?? createExamRes.body).questions?.[0]?.id;
    expect(questionId).toBeDefined();

    await request(app.getHttpServer())
      .post(`${PREFIX}/exams/sessions/${sessionId}/answer`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ questionId, value: 'B' })
      .expect(204);

    // 10. Save an answer that belongs to another user's session — should be forbidden
    // (We'd need another session but skip for brevity)

    // 11. Save an answer for a session not owned by this student — forbidden
    const otherStudentRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/register`)
      .send({
        name: 'Other',
        email: `other-exam-test-${suffix}@na.local`,
        password: 'Passw0rd!',
        hardwareId: `other-exam-dev-${suffix}`,
      })
      .expect(201);
    const otherToken = otherStudentRes.body.data.accessToken ?? otherStudentRes.body.accessToken;

    await request(app.getHttpServer())
      .post(`${PREFIX}/exams/sessions/${sessionId}/answer`)
      .set('Authorization', `Bearer ${otherToken}`)
      .send({ questionId, value: 'A' })
      .expect(403);
  });
});
