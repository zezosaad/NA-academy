import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Device, DeviceSchema } from './schemas/device.schema.js';
import { DevicesService } from './devices.service.js';
import { PushTokensModule } from '../push-tokens/push-tokens.module.js';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Device.name, schema: DeviceSchema }]),
    PushTokensModule,
  ],
  providers: [DevicesService],
  exports: [DevicesService],
})
export class DevicesModule {}
