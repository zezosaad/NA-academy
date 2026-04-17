import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SecurityFlag, SecurityFlagSchema } from './schemas/security-flag.schema.js';
import { SecurityService } from './security.service.js';
import { SecurityController } from './security.controller.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: SecurityFlag.name, schema: SecurityFlagSchema }]),
    AuthModule,
  ],
  providers: [SecurityService],
  controllers: [SecurityController],
})
export class SecurityModule {}
