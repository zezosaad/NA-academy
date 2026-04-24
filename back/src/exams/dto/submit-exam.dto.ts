import {
  IsMongoId,
  IsNotEmpty,
  IsArray,
  ValidateNested,
  IsString,
  ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class AnswerDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  @IsNotEmpty()
  questionId!: string;

  @ApiProperty({ example: 'A' })
  @IsString()
  @IsNotEmpty()
  selectedOption!: string;
}

export class SubmitExamDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439015' })
  @IsMongoId()
  @IsNotEmpty()
  examSessionId!: string;

  @ApiProperty({ type: [AnswerDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => AnswerDto)
  answers!: AnswerDto[];
}
