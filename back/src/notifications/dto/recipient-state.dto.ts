import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RecipientStateDto {
  @ApiProperty()
  userId!: string;

  @ApiProperty()
  userName!: string;

  @ApiProperty({ enum: ['pending', 'delivered', 'failed'] })
  state!: string;

  @ApiPropertyOptional()
  failureReason?: string;

  @ApiPropertyOptional()
  deliveredAt?: string;

  @ApiPropertyOptional()
  readAt?: string;
}

export class InboxItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty()
  body!: string;

  @ApiPropertyOptional({ type: 'object', additionalProperties: { type: 'string' } })
  data?: Record<string, string>;

  @ApiProperty()
  createdAt!: string;

  @ApiPropertyOptional()
  readAt?: string;

  @ApiPropertyOptional()
  senderName?: string;
}

export class InboxResponseDto {
  @ApiProperty({ type: [InboxItemDto] })
  items!: InboxItemDto[];

  @ApiPropertyOptional()
  nextCursor?: string;

  @ApiProperty()
  unreadCount!: number;
}

export class NotificationDetailResponseDto {
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

  @ApiProperty()
  audience!: object;

  @ApiProperty()
  stats!: object;

  @ApiProperty()
  createdAt!: string;

  @ApiPropertyOptional({ type: [RecipientStateDto] })
  recipients?: RecipientStateDto[];

  @ApiPropertyOptional()
  recipientsTotal?: number;

  @ApiPropertyOptional()
  recipientsLimit?: number;

  @ApiPropertyOptional()
  recipientsNextCursor?: string;

  @ApiPropertyOptional()
  recipientsArchived?: boolean;

  @ApiPropertyOptional()
  recipientsArchivedAt?: string;
}
