import { IsString, Length, IsOptional, IsObject, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AudienceDto } from './audience.dto.js';
import { ValidateData } from './validators/data-payload.validator.js';

export class CreateNotificationDto {
  @ApiProperty({ minLength: 1, maxLength: 100 })
  @IsString()
  @Length(1, 100)
  title!: string;

  @ApiProperty({ minLength: 1, maxLength: 1000 })
  @IsString()
  @Length(1, 1000)
  body!: string;

  @ApiPropertyOptional({ type: 'object', additionalProperties: { type: 'string' } })
  @IsObject()
  @IsOptional()
  @ValidateData()
  data?: Record<string, string>;

  @ApiProperty({ type: AudienceDto })
  @ValidateNested()
  @Type(() => AudienceDto)
  audience!: AudienceDto;
}
