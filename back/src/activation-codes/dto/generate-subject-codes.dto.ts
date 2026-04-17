import { IsMongoId, IsInt, Min, Max, IsOptional, ValidateIf } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GenerateSubjectCodesDto {
  @ApiPropertyOptional({ example: '507f1f77bcf86cd799439011' })
  @ValidateIf(o => !o.bundleId)
  @IsMongoId()
  subjectId?: string;

  @ApiPropertyOptional({ example: '507f1f77bcf86cd799439012' })
  @ValidateIf(o => !o.subjectId)
  @IsMongoId()
  bundleId?: string;

  @ApiProperty({ example: 500 })
  @IsInt()
  @Min(1)
  @Max(10000)
  quantity!: number;
}
