import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { AudienceKind } from './audience.dto.js';

export class NotificationStatsDto {
  @ApiProperty()
  total!: number;

  @ApiProperty()
  delivered!: number;

  @ApiProperty()
  failed!: number;

  @ApiProperty()
  read!: number;
}

export class AudienceResponseDto {
  @ApiProperty({ enum: ['all', 'user-list', 'subject'] })
  kind!: AudienceKind;

  @ApiPropertyOptional({ type: [String] })
  userIds?: string[];

  @ApiPropertyOptional()
  subjectId?: string;

  @ApiProperty()
  resolvedRecipientCount!: number;
}

export class NotificationResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty()
  body!: string;

  @ApiPropertyOptional({ type: 'object', additionalProperties: { type: 'string' } })
  data?: Record<string, string>;

  @ApiProperty()
  senderId!: string;

  @ApiProperty()
  senderName!: string;

  @ApiProperty({ enum: ['admin', 'teacher'] })
  senderRole!: string;

  @ApiProperty({ type: AudienceResponseDto })
  audience!: AudienceResponseDto;

  @ApiProperty({ type: NotificationStatsDto })
  stats!: NotificationStatsDto;

  @ApiProperty()
  createdAt!: string;
}
