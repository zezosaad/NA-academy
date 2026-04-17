import { IsArray, IsMongoId, IsNotEmpty, IsString, ArrayMinSize } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateBundleDto {
  @ApiProperty({ example: 'Science Bundle' })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: ['507f1f77bcf86cd799439011'], type: [String] })
  @IsArray()
  @ArrayMinSize(1)
  @IsMongoId({ each: true })
  subjectIds!: string[];
}
