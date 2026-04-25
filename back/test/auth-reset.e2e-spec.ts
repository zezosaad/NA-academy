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
import { PasswordReset, PasswordResetDocument } from '../src/auth/schemas/password-reset.schema.js';

describe('Auth - Password Reset (e2e)', () => {
  let app: INestApplication<App>;
  let passwordResetModel: Model<PasswordResetDocument>;

  const PREFIX = '/api/v1';
  const suffix = Date.now();

  const adminEmail = `admin-reset-test-${suffix}@na.local`;
  const studentEmail = `student-reset-test-${suffix}@na.local`;
  const studentPassword = 'Passw0rd!';
  const hardwareId = `reset-dev-${suffix}`;

  let adminToken: string;
  let studentToken: string;

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

    passwordResetModel = moduleFixture.get<Model<PasswordResetDocument>>(
      getModelToken(PasswordReset.name),
    );

    const adminRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/register-admin`)
      .send({
        name: 'Admin',
        email: adminEmail,
        password: 'Passw0rd!',
        hardwareId: `admin-reset-dev-${suffix}`,
      })
      .expect(201);
    adminToken = adminRes.body.data.accessToken ?? adminRes.body.accessToken;

    const studentRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/register`)
      .send({
        name: 'Student',
        email: studentEmail,
        password: studentPassword,
        hardwareId: hardwareId,
      })
      .expect(201);
    studentToken = studentRes.body.data.accessToken ?? studentRes.body.accessToken;
  });

  afterAll(async () => {
    if (passwordResetModel) {
      await passwordResetModel.deleteMany({});
    }
    if (app) {
      await app.close();
    }
  });

  it('should return 204 for unknown email (no account-existence disclosure)', async () => {
    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/forgot-password`)
      .send({ email: `nonexistent-${suffix}@na.local` })
      .expect(204);

    const count = await passwordResetModel.countDocuments();
    expect(count).toBe(0);
  });

  it('should return 204 for known email and create a PasswordReset row', async () => {
    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/forgot-password`)
      .send({ email: studentEmail })
      .expect(204);

    const count = await passwordResetModel.countDocuments();
    expect(count).toBeGreaterThan(0);
  });

  it('should reject reset with invalid token with 410', async () => {
    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/reset-password`)
      .send({
        token: 'invalid-token-value',
        newPassword: 'NewPassw0rd!',
        hardwareId: hardwareId,
      })
      .expect(410);
  });

  it('should reject reset with expired token with 410', async () => {
    const crypto = require('crypto');
    const expiredRawToken = 'expired-test-token';
    const expiredTokenHash = crypto.createHash('sha256').update(expiredRawToken).digest('hex');
    const studentUser = await passwordResetModel.db.model('User').findOne({ email: studentEmail });
    await passwordResetModel.create({
      userId: studentUser!._id,
      tokenHash: expiredTokenHash,
      expiresAt: new Date(Date.now() - 60 * 1000),
      consumed: false,
    });

    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/reset-password`)
      .send({
        token: expiredRawToken,
        newPassword: 'NewPassw0rd!',
        hardwareId: hardwareId,
      })
      .expect(410);
  });

  it('should reject reset with consumed token with 410', async () => {
    const crypto = require('crypto');
    const consumedRawToken = 'consumed-test-token';
    const consumedTokenHash = crypto.createHash('sha256').update(consumedRawToken).digest('hex');
    const studentUser = await passwordResetModel.db.model('User').findOne({ email: studentEmail });
    await passwordResetModel.create({
      userId: studentUser!._id,
      tokenHash: consumedTokenHash,
      expiresAt: new Date(Date.now() + 30 * 60 * 1000),
      consumed: true,
      consumedAt: new Date(),
    });

    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/reset-password`)
      .send({
        token: consumedRawToken,
        newPassword: 'NewPassw0rd!',
        hardwareId: hardwareId,
      })
      .expect(410);
  });

  it('should successfully reset password and return user + tokens', async () => {
    await passwordResetModel.deleteMany({});

    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/forgot-password`)
      .send({ email: studentEmail })
      .expect(204);

    const resetDoc = await passwordResetModel.findOne({ consumed: false });
    expect(resetDoc).toBeDefined();

    const fakeRawToken = 'test-raw-token-for-reset';
    const crypto = require('crypto');
    const tokenHash = crypto.createHash('sha256').update(fakeRawToken).digest('hex');
    resetDoc!.tokenHash = tokenHash;
    await resetDoc!.save();

    const resetRes = await request(app.getHttpServer())
      .post(`${PREFIX}/auth/reset-password`)
      .send({
        token: fakeRawToken,
        newPassword: 'NewPassw0rd!',
        hardwareId: hardwareId,
      })
      .expect(200);

    const body = resetRes.body.data ?? resetRes.body;
    expect(body.user).toBeDefined();
    expect(body.user.email).toBe(studentEmail);
    expect(body.tokens).toBeDefined();
    expect(body.tokens.accessToken).toBeDefined();
    expect(body.tokens.refreshToken).toBeDefined();

    const updatedDoc = await passwordResetModel.findById(resetDoc!._id);
    expect(updatedDoc!.consumed).toBe(true);
  });

  it('should let the user log in with the new password', async () => {
    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/login`)
      .send({
        email: studentEmail,
        password: 'NewPassw0rd!',
        hardwareId: hardwareId,
      })
      .expect(200);
  });

  it('should reject login with the old password', async () => {
    await request(app.getHttpServer())
      .post(`${PREFIX}/auth/login`)
      .send({
        email: studentEmail,
        password: studentPassword,
        hardwareId: hardwareId,
      })
      .expect(401);
  });
});
