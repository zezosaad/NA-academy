import { NestFactory } from '@nestjs/core';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersModule } from '../users/users.module.js';
import { UsersService } from '../users/users.service.js';
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
  ],
})
class CheckModule {}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(CheckModule);
  const usersService = app.get(UsersService);
  const configService = app.get(ConfigService);

  const adminEmail = configService.get<string>('ADMIN_EMAIL') || 'admin@example.com';
  const user = await usersService.findByEmail(adminEmail);

  if (user) {
    console.log('--- Admin User Data ---');
    console.log('ID:', user._id);
    console.log('Email:', user.email);
    console.log('Role:', user.role);
    console.log('Status:', user.status);
    console.log('-----------------------');
  } else {
    console.log('Admin user not found!');
  }

  await app.close();
  process.exit(0);
}

bootstrap();
