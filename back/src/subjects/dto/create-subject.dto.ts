import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

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
}
