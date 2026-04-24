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
import { Subject, SubjectDocument } from '../src/subjects/schemas/subject.schema.js';
import {
  SubjectCode,
  SubjectCodeDocument,
} from '../src/activation-codes/schemas/subject-code.schema.js';

describe('Subjects - isUnlocked (e2e)', () => {
  let app: INestApplication<App>;
  let subjectModel: Model<SubjectDocument>;
  let subjectCodeModel: Model<SubjectCodeDocument>;

  let adminToken: string;
  let studentToken: string;
  let subjectId: string;
  let codeValue: string;

  const createdSubjectIds: string[] = [];
  const createdSubjectCodeIds: string[] = [];

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

    subjectModel = moduleFixture.get<Model<SubjectDocument>>(getModelToken(Subject.name));
    subjectCodeModel = moduleFixture.get<Model<SubjectCodeDocument>>(
      getModelToken(SubjectCode.name),
    );
  });

  afterAll(async () => {
    if (createdSubjectIds.length > 0) {
      await subjectModel.deleteMany({ _id: { $in: createdSubjectIds } });
    }
    if (createdSubjectCodeIds.length > 0) {
      await subjectCodeModel.deleteMany({ _id: { $in: createdSubjectCodeIds } });
    }
    await app.close();
  });

  it('should register admin and student, seed data, and verify isUnlocked', async () => {
    const suffix = Date.now();
    // 1. Register admin
    const adminRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/register-admin`)
      .send({
        name: 'Admin',
        email: `admin-subj-test-${suffix}@na.local`,
        password: 'Passw0rd!',
        hardwareId: `admin-subj-dev-${suffix}`,
      })
      .expect(201);
    adminToken = adminRes.body.data.accessToken ?? adminRes.body.accessToken;

    // 2. Register student
    const studentRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/register`)
      .send({
        name: 'Student',
        email: `student-subj-test-${suffix}@na.local`,
        password: 'Passw0rd!',
        hardwareId: `student-subj-dev-${suffix}`,
      })
      .expect(201);
    studentToken = studentRes.body.data.accessToken ?? studentRes.body.accessToken;

    // 3. Create a subject as admin
    const subjectRes = await request(app.getHttpServer())
      .post(`${PREFIX}/subjects`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ title: 'Test Subject', description: 'For isUnlocked test', category: 'Testing' })
      .expect(201);
    subjectId =
      (subjectRes.body.data ?? subjectRes.body)._id ?? (subjectRes.body.data ?? subjectRes.body).id;
    createdSubjectIds.push(subjectId);

    // 4. Generate subject activation codes as admin
    const codesRes = await request(app.getHttpServer())
      .post(`${PREFIX}/activation-codes/subject/generate`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ subjectId, quantity: 1 })
      .expect(201);
    const batchId = (codesRes.body.data ?? codesRes.body).batchId;

    // 5. Get the code value from the batch
    const batchRes = await request(app.getHttpServer())
      .get(`${PREFIX}/activation-codes/batch/${batchId}?page=1&limit=1`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    const batchData = batchRes.body.data ?? batchRes.body;
    const batchItems = batchData.data ?? batchData;
    expect(batchItems.length, 'Batch should contain at least one code').toBeGreaterThan(0);
    const codeItem = batchItems[0];
    codeValue = codeItem.code;
    if (codeItem._id || codeItem.id) {
      createdSubjectCodeIds.push(codeItem._id ?? codeItem.id);
    }

    // 6. As student, GET /subjects → isUnlocked should be false
    const beforeActivate = await request(app.getHttpServer())
      .get(`${PREFIX}/subjects`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);

    const subjectsBefore = beforeActivate.body.data ?? beforeActivate.body;
    const subjectList: any[] = subjectsBefore.data ?? subjectsBefore;
    const subjectBefore = subjectList.find((s: any) => (s._id ?? s.id) === subjectId);
    expect(subjectBefore).toBeDefined();
    expect(subjectBefore.isUnlocked).toBe(false);

    // 7. Activate the code as student
    await request(app.getHttpServer())
      .post(`${PREFIX}/activation-codes/activate`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ code: codeValue })
      .expect(200);

    // 8. As student, GET /subjects → isUnlocked should be true
    const afterActivate = await request(app.getHttpServer())
      .get(`${PREFIX}/subjects`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);

    const subjectsAfter = afterActivate.body.data ?? afterActivate.body;
    const subjectListAfter: any[] = subjectsAfter.data ?? subjectsAfter;
    const subjectAfter = subjectListAfter.find((s: any) => (s._id ?? s.id) === subjectId);
    expect(subjectAfter).toBeDefined();
    expect(subjectAfter.isUnlocked).toBe(true);

    // 9. As admin, GET /subjects → isUnlocked should be false (admin is not a student)
    const adminSubjects = await request(app.getHttpServer())
      .get(`${PREFIX}/subjects`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    const adminSubjectData = adminSubjects.body.data ?? adminSubjects.body;
    const adminSubjectList: any[] = adminSubjectData.data ?? adminSubjectData;
    const adminSubject = adminSubjectList.find((s: any) => (s._id ?? s.id) === subjectId);
    expect(adminSubject).toBeDefined();
    expect(adminSubject.isUnlocked).toBe(false);
  });
});
