import { IsEmail, IsEnum, IsNotEmpty, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { EducationLevel } from '../../common/enums/education-level.enum.js';

export class RegisterDto {
  @ApiProperty({ example: 'student@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: 'securePass123', minLength: 6 })
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password!: string;

  @ApiProperty({ example: 'Ahmed Hassan' })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: 'device-fingerprint-string' })
  @IsString()
  @IsNotEmpty()
  hardwareId!: string;

  @ApiProperty({ enum: EducationLevel, example: EducationLevel.SECONDARY_3 })
  @IsEnum(EducationLevel)
  level!: EducationLevel;
}
