import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsBoolean, IsNumber, IsOptional, IsDateString } from 'class-validator';

class MessagePreviewDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  text?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  hasImage?: boolean;

  @ApiProperty()
  @IsDateString()
  sentAt!: string;

  @ApiProperty()
  @IsString()
  senderId!: string;

  @ApiProperty()
  @IsString()
  status!: string;
}

export class ConversationPreviewDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty()
  @IsBoolean()
  virtual!: boolean;

  @ApiProperty()
  @IsString()
  counterpartyId!: string;

  @ApiProperty()
  @IsString()
  counterpartyName!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  counterpartyAvatarUrl?: string | null;

  @ApiProperty()
  @IsString()
  subjectId!: string;

  @ApiProperty()
  @IsString()
  subjectTitle!: string;

  @ApiPropertyOptional()
  lastMessage?: MessagePreviewDto | null;

  @ApiProperty()
  @IsNumber()
  unreadCount!: number;
}

export class ConversationListResponseDto {
  @ApiProperty({ type: [ConversationPreviewDto] })
  conversations!: ConversationPreviewDto[];
}
