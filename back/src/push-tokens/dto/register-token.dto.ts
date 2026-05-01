import { IsString, Length, IsIn, IsOptional, IsMongoId } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterTokenDto {
  @ApiProperty({ minLength: 50, maxLength: 4096 })
  @IsString()
  @Length(50, 4096)
  token!: string;

  @ApiProperty({ enum: ['ios', 'android'] })
  @IsIn(['ios', 'android'])
  platform!: string;

  @ApiPropertyOptional({ maxLength: 64 })
  @IsString()
  @IsOptional()
  @Length(1, 64)
  appVersion?: string;

  @ApiPropertyOptional()
  @IsMongoId()
  @IsOptional()
  deviceId?: string;
}

export class RefreshTokenDto {
  @ApiPropertyOptional({ minLength: 50, maxLength: 4096 })
  @IsString()
  @IsOptional()
  @Length(50, 4096)
  token?: string;

  @ApiPropertyOptional({ maxLength: 64 })
  @IsString()
  @IsOptional()
  @Length(1, 64)
  appVersion?: string;
}

export class PushTokenResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ enum: ['ios', 'android'] })
  platform!: string;

  @ApiPropertyOptional()
  appVersion?: string;

  @ApiPropertyOptional()
  deviceId?: string;

  @ApiProperty()
  lastSeenAt!: string;

  @ApiProperty()
  createdAt!: string;
}
