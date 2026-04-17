import { IsEnum, IsMongoId, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MediaType } from '../schemas/media-asset.schema.js';

export class UploadMediaDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  @IsNotEmpty()
  subjectId!: string;

  @ApiProperty({ enum: MediaType })
  @IsEnum(MediaType)
  @IsNotEmpty()
  mediaType!: MediaType;

  @ApiPropertyOptional({ example: 'Introduction Video' })
  @IsOptional()
  @IsString()
  title?: string;
}
