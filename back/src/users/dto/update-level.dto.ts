import { IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { EducationLevel } from '../../common/enums/education-level.enum.js';

export class UpdateLevelDto {
  @ApiProperty({ enum: EducationLevel, example: EducationLevel.SECONDARY_3 })
  @IsEnum(EducationLevel)
  level!: EducationLevel;
}
