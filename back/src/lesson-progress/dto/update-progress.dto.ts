import { IsInt, IsNumber, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateProgressDto {
  @ApiProperty({ example: 145, description: 'Furthest watched position in seconds' })
  @IsNumber()
  @Min(0)
  watchedSeconds!: number;

  @ApiProperty({ example: 600, description: 'Full video duration in seconds' })
  @IsInt()
  @Min(0)
  durationSeconds!: number;
}
