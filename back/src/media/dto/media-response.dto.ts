import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MediaType } from '../schemas/media-asset.schema.js';

export class MediaResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  gridFsFileId!: string;

  @ApiProperty()
  filename!: string;

  @ApiProperty()
  contentType!: string;

  @ApiProperty()
  fileSize!: number;

  @ApiProperty({ enum: MediaType })
  mediaType!: MediaType;

  @ApiPropertyOptional()
  title?: string;
}
