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
import { User, UserDocument } from '../src/users/schemas/user.schema.js';
import { Subject, SubjectDocument } from '../src/subjects/schemas/subject.schema.js';
import {
  SubjectCode,
  SubjectCodeDocument,
} from '../src/activation-codes/schemas/subject-code.schema.js';
import { Conversation, ConversationDocument } from '../src/chat/schemas/conversation.schema.js';

describe('Chat - canChat scoping (e2e)', () => {
  let app: INestApplication<App>;
  let userModel: Model<UserDocument>;
  let subjectModel: Model<SubjectDocument>;
  let subjectCodeModel: Model<SubjectCodeDocument>;
  let conversationModel: Model<ConversationDocument>;

  let adminToken: string;
  let studentId: string;
  let teacherId: string;
  let subjectId: string;

  const createdUserIds: string[] = [];
  const createdSubjectIds: string[] = [];
  const createdCodeIds: string[] = [];
  const createdConversationIds: string[] = [];

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

    userModel = moduleFixture.get<Model<UserDocument>>(getModelToken(User.name));
    subjectModel = moduleFixture.get<Model<SubjectDocument>>(getModelToken(Subject.name));
    subjectCodeModel = moduleFixture.get<Model<SubjectCodeDocument>>(
      getModelToken(SubjectCode.name),
    );
    conversationModel = moduleFixture.get<Model<ConversationDocument>>(
      getModelToken(Conversation.name),
    );
  });

  afterAll(async () => {
    await userModel.deleteMany({ _id: { $in: createdUserIds } });
    await subjectModel.deleteMany({ _id: { $in: createdSubjectIds } });
    await subjectCodeModel.deleteMany({ _id: { $in: createdCodeIds } });
    await conversationModel.deleteMany({ _id: { $in: createdConversationIds } });
    if (app) {
      await app.close();
    }
  });

  describe('canChat', () => {
    it('student can chat with teacher who teaches an unlocked subject', async () => {
      const adminRes = await request(app.getHttpServer())
        .post(`${PREFIX}/auth/register-admin`)
        .send({
          name: 'ChatAdmin',
          email: 'chat-admin@test.local',
          password: 'Passw0rd!',
          hardwareId: 'chat-admin-hw',
        });
      adminToken = adminRes.body.tokens.accessToken;

      const teacherRes = await request(app.getHttpServer()).post(`${PREFIX}/auth/register`).send({
        name: 'ChatTeacher',
        email: 'chat-teacher@test.local',
        password: 'Passw0rd!',
        hardwareId: 'chat-teacher-hw',
        role: 'teacher',
      });
      teacherId = teacherRes.body.user.id;
      teacherToken = teacherRes.body.tokens.accessToken;

      const studentRes = await request(app.getHttpServer()).post(`${PREFIX}/auth/register`).send({
        name: 'ChatStudent',
        email: 'chat-student@test.local',
        password: 'Passw0rd!',
        hardwareId: 'chat-student-hw',
      });
      studentId = studentRes.body.user.id;
      studentToken = studentRes.body.tokens.accessToken;

      createdUserIds.push(adminRes.body.user.id, teacherRes.body.user.id, studentRes.body.user.id);

      const subjectRes = await request(app.getHttpServer())
        .post(`${PREFIX}/subjects`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          title: 'Chat Test Subject',
          description: 'Subject for chat canChat test',
          category: 'test',
        });
      subjectId = subjectRes.body._id ?? subjectRes.body.id;
      createdSubjectIds.push(subjectId);

      await request(app.getHttpServer())
        .put(`${PREFIX}/users/${teacherId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ assignedSubjects: [subjectId] });

      const codeRes = await request(app.getHttpServer())
        .post(`${PREFIX}/activation-codes/subject/generate`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ subjectId, count: 1 });

      const codeValue = codeRes.body.codes?.[0]?.code ?? codeRes.body.code;
      const codeDoc = await subjectCodeModel.findOne({ code: codeValue }).exec();
      if (codeDoc) createdCodeIds.push(codeDoc._id.toString());

      await request(app.getHttpServer())
        .post(`${PREFIX}/activation-codes/activate`)
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ code: codeValue });

      const conversationsRes = await request(app.getHttpServer())
        .get(`${PREFIX}/chat/conversations`)
        .set('Authorization', `Bearer ${studentToken}`)
        .expect(200);

      expect(conversationsRes.body.conversations).toBeDefined();
      const teacherConversation = conversationsRes.body.conversations.find(
        (c: any) => c.counterpartyId === teacherId,
      );
      expect(teacherConversation).toBeDefined();
      expect(teacherConversation.virtual).toBe(true);
      expect(teacherConversation.subjectId).toBe(subjectId);
    });

    it('student cannot chat with a teacher whose subject they have NOT unlocked', async () => {
      const otherTeacherRes = await request(app.getHttpServer())
        .post(`${PREFIX}/auth/register`)
        .send({
          name: 'OtherTeacher',
          email: 'chat-other-teacher@test.local',
          password: 'Passw0rd!',
          hardwareId: 'chat-other-teacher-hw',
          role: 'teacher',
        });
      const otherTeacherId = otherTeacherRes.body.user.id;
      createdUserIds.push(otherTeacherId);

      const otherSubjectRes = await request(app.getHttpServer())
        .post(`${PREFIX}/subjects`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          title: 'Other Subject',
          description: 'Unlocked subject',
          category: 'test',
        });
      const otherSubjectId = otherSubjectRes.body._id ?? otherSubjectRes.body.id;
      createdSubjectIds.push(otherSubjectId);

      await request(app.getHttpServer())
        .put(`${PREFIX}/users/${otherTeacherId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ assignedSubjects: [otherSubjectId] });

      const conversationsRes = await request(app.getHttpServer())
        .get(`${PREFIX}/chat/conversations`)
        .set('Authorization', `Bearer ${studentToken}`);

      const otherTeacherConv = (conversationsRes.body.conversations ?? []).find(
        (c: any) => c.counterpartyId === otherTeacherId,
      );
      expect(otherTeacherConv).toBeUndefined();
    });
  });
});
