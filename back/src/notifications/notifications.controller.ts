import { Controller } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Notifications')
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {}
