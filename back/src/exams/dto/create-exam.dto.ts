import { IsString, IsNotEmpty, IsArray, IsMongoId, IsBoolean, IsOptional, IsInt, Min, ValidateNested, ArrayMinSize } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

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
