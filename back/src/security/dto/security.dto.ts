import { IsEnum, IsMongoId, IsNotEmpty, IsObject, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FlagType, ActionTaken } from '../schemas/security-flag.schema.js';

export class ReportFlagDto {
  @ApiProperty({ enum: FlagType })
  @IsEnum(FlagType)
  @IsNotEmpty()
  flagType!: FlagType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsObject()
  metadata?: Record<string, any>;
}

export class ReviewFlagDto {
  @ApiProperty({ enum: ActionTaken })
  @IsEnum(ActionTaken)
  @IsNotEmpty()
  actionTaken!: ActionTaken;
}

export class ListFlagsQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  studentId?: string;

  @ApiPropertyOptional({ enum: FlagType })
  @IsOptional()
  @IsEnum(FlagType)
  flagType?: FlagType;
}
