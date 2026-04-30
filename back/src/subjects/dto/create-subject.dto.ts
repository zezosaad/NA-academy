import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { EducationLevel } from '../../common/enums/education-level.enum.js';

export class CreateSubjectDto {
  @ApiProperty({ example: 'Algebra I' })
  @IsString()
  @IsNotEmpty()
  title!: string;

  @ApiPropertyOptional({ example: 'Introduction to algebraic concepts' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 'Mathematics' })
  @IsString()
  @IsNotEmpty()
  category!: string;

  @ApiProperty({ enum: EducationLevel, example: EducationLevel.SECONDARY_3 })
  @IsEnum(EducationLevel)
  level!: EducationLevel;
}
