import { IsMongoId, IsDefined, ValidateIf, IsString, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SaveAnswerDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  questionId!: string;

  @ApiProperty({
    example: 'A',
    description: 'A single answer value or an array of values for multi-select',
  })
  @IsDefined()
  @ValidateIf((o) => typeof o.value === 'string')
  @IsString()
  @ValidateIf((o) => Array.isArray(o.value))
  @IsArray()
  value!: string | string[];
}
