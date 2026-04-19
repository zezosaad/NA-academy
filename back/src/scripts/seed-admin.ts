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
class SeedModule {}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(SeedModule);
  const usersService = app.get(UsersService);
  const configService = app.get(ConfigService);

  const adminEmail = configService.get<string>('ADMIN_EMAIL') || 'admin@example.com';
  const adminPassword = configService.get<string>('ADMIN_PASSWORD') || 'SuperSecret123!';

  console.log(`Checking for admin user: ${adminEmail}...`);

  const existingAdmin = await usersService.findByEmail(adminEmail);
  if (existingAdmin) {
    console.log('Admin user already exists. Updating password to ensure it is hashed...');
    existingAdmin.passwordHash = await (await import('bcrypt')).hash(adminPassword, 12);
    existingAdmin.role = (await import('../users/schemas/user.schema.js')).UserRole.ADMIN;
    await existingAdmin.save();
    console.log('Admin user updated successfully.');
  } else {
    console.log('Creating initial admin user...');
    await usersService.createAdminUser({
      email: adminEmail,
      password: adminPassword,
      name: 'System Admin',
    });
    console.log('Admin user created successfully.');
  }

  await app.close();
  process.exit(0);
}

bootstrap().catch(err => {
  console.error('Failed to seed admin user:', err);
  process.exit(1);
});
