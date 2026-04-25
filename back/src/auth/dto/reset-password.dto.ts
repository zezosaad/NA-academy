import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResetPasswordDto {
  @ApiProperty({ example: 'abc123token' })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({ example: 'newSecurePass123', minLength: 8 })
  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  newPassword!: string;

  @ApiProperty({ example: 'device-fingerprint-string' })
  @IsString()
  @IsNotEmpty()
  hardwareId!: string;
}
