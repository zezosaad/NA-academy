import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { WatchTime, WatchTimeSchema } from './schemas/watch-time.schema.js';
import { AnalyticsService } from './analytics.service.js';
import { AnalyticsController } from './analytics.controller.js';
import { MediaModule } from '../media/media.module.js';
import { ActivationCodesModule } from '../activation-codes/activation-codes.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: WatchTime.name, schema: WatchTimeSchema }]),
    MediaModule,
    ActivationCodesModule, // for AccessCheckHelper
  ],
  providers: [AnalyticsService],
  controllers: [AnalyticsController],
})
export class AnalyticsModule {}
