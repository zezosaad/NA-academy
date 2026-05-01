import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PushToken, PushTokenSchema } from './schemas/push-token.schema.js';
import { PushTokensService } from './push-tokens.service.js';
import { PushTokensController } from './push-tokens.controller.js';

@Module({
  imports: [MongooseModule.forFeature([{ name: PushToken.name, schema: PushTokenSchema }])],
  controllers: [PushTokensController],
  providers: [PushTokensService],
  exports: [PushTokensService],
})
export class PushTokensModule {}
