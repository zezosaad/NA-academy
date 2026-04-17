import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module.js';
import { UsersService } from '../users/users.service.js';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const usersService = app.get(UsersService);
  const configService = app.get(ConfigService);

  const adminEmail = configService.get<string>('ADMIN_EMAIL') || 'admin@example.com';
  const adminPassword = configService.get<string>('ADMIN_PASSWORD') || 'SuperSecret123!';

  console.log(`Checking for admin user: ${adminEmail}...`);

  const existingAdmin = await usersService.findByEmail(adminEmail);
  if (existingAdmin) {
    console.log('Admin user already exists. Exiting...');
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
