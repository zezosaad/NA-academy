import { IsOptional, IsString, Length, IsIn, IsMongoId, IsISO8601, IsInt, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import type { AudienceKind } from './audience.dto.js';

export class NotificationListQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 100)
  q?: string;

  @ApiPropertyOptional({ enum: ['all', 'user-list', 'subject'] })
  @IsOptional()
  @IsIn(['all', 'user-list', 'subject'])
  audienceKind?: AudienceKind;

  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  subjectId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsISO8601()
  before?: string;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
