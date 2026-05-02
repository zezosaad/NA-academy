import { IsMongoId, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GrantRetakePermitDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  @IsNotEmpty()
  studentId!: string;

  @ApiPropertyOptional({ example: 'Student requested retake after connection drop' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
