import { IsEmail, IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'student@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: 'securePass123' })
  @IsString()
  @IsNotEmpty()
  password!: string;

  @ApiProperty({ example: 'device-fingerprint-string' })
  @IsString()
  @IsNotEmpty()
  hardwareId!: string;
}
