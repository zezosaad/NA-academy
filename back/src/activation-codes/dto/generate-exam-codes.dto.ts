import { IsMongoId, IsInt, Min, Max, IsEnum, IsOptional, ValidateIf } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ExamUsageType } from '../schemas/exam-code.schema.js';

export class GenerateExamCodesDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  examId!: string;

  @ApiProperty({ example: 200 })
  @IsInt()
  @Min(1)
  @Max(10000)
  quantity!: number;

  @ApiProperty({ enum: ExamUsageType })
  @IsEnum(ExamUsageType)
  usageType!: ExamUsageType;

  @ApiPropertyOptional({ example: 5 })
  @ValidateIf(o => o.usageType === ExamUsageType.MULTI)
  @IsInt()
  @Min(2)
  maxUses?: number;

  @ApiPropertyOptional({ example: 1440 })
  @IsOptional()
  @IsInt()
  @Min(1)
  timeLimitMinutes?: number;
}
