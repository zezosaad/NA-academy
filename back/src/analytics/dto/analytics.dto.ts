import { IsMongoId, IsNotEmpty, IsNumber, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class TrackWatchTimeDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  @IsNotEmpty()
  mediaAssetId!: string;

  @ApiProperty({ example: 120 })
  @IsNumber()
  @Min(1)
  durationSeconds!: number;
}
