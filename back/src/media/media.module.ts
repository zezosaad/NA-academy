import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MediaAsset, MediaAssetSchema } from './schemas/media-asset.schema.js';
import { MediaService } from './media.service.js';
import { MediaController } from './media.controller.js';
import { ActivationCodesModule } from '../activation-codes/activation-codes.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: MediaAsset.name, schema: MediaAssetSchema }]),
    ActivationCodesModule,
  ],
  controllers: [MediaController],
  providers: [MediaService],
  exports: [MediaService],
})
export class MediaModule {}
