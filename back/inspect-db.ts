import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module.js';
import { getModelToken } from '@nestjs/mongoose';
import { Model } from 'mongoose';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const subjectModel = app.get(getModelToken('Subject'));
  const subjects = await subjectModel.find().exec();
  console.log('SUBJECTS IN DB:', JSON.stringify(subjects, null, 2));
  await app.close();
}
bootstrap();
