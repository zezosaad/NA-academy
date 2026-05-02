import {
  IsString,
  IsNotEmpty,
  IsArray,
  IsMongoId,
  IsBoolean,
  IsOptional,
  IsInt,
  Min,
  IsEnum,
  IsDateString,
  ValidateNested,
  ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ExamAccessMode, ExamTimingMode } from '../schemas/exam.schema.js';

export class QuestionOptionDto {
  @ApiProperty({ example: 'A' })
  @IsString()
  @IsNotEmpty()
  label!: string;

  @ApiProperty({ example: 'x = 1' })
  @IsString()
  @IsNotEmpty()
  text!: string;
}

export class CreateQuestionDto {
  @ApiProperty({ example: 'Solve for x: 2x = 2' })
  @IsString()
  @IsNotEmpty()
  text!: string;

  @ApiProperty({ type: [QuestionOptionDto] })
  @IsArray()
  @ArrayMinSize(2)
  @ValidateNested({ each: true })
  @Type(() => QuestionOptionDto)
  options!: QuestionOptionDto[];

  @ApiProperty({ example: 'A' })
  @IsString()
  @IsNotEmpty()
  correctOption!: string;

  @ApiProperty({ example: 60 })
  @IsInt()
  @Min(5)
  timeLimitSeconds!: number;

  @ApiPropertyOptional({ example: '507f1f77bcf86cd799439011' })
  @IsOptional()
  @IsMongoId()
  imageRef?: string;

  @ApiProperty({ example: 1 })
  @IsInt()
  order!: number;
}

export class CreateExamDto {
  @ApiProperty({ example: 'Algebra Midterm' })
  @IsString()
  @IsNotEmpty()
  title!: string;

  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  @IsNotEmpty()
  subjectId!: string;

  @ApiPropertyOptional({
    enum: ExamAccessMode,
    example: ExamAccessMode.CODE_REQUIRED,
  })
  @IsOptional()
  @IsEnum(ExamAccessMode)
  accessMode?: ExamAccessMode;

  @ApiPropertyOptional({
    enum: ExamTimingMode,
    example: ExamTimingMode.PER_QUESTION,
  })
  @IsOptional()
  @IsEnum(ExamTimingMode)
  timingMode?: ExamTimingMode;

  @ApiPropertyOptional({ example: 45 })
  @IsOptional()
  @IsInt()
  @Min(1)
  examTimeLimitMinutes?: number;

  @ApiPropertyOptional({ example: '2026-05-10T09:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  availableFrom?: string | null;

  @ApiPropertyOptional({ example: '2026-05-10T11:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  availableUntil?: string | null;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  hasFreeSection?: boolean;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  freeQuestionCount?: number;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  freeAttemptLimit?: number;

  @ApiProperty({ type: [CreateQuestionDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateQuestionDto)
  questions!: CreateQuestionDto[];
}
