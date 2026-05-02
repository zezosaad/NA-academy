import { IsEmail, IsOptional, IsString, IsNotEmpty } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Ahmed Hassan' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  name?: string;

  @ApiPropertyOptional({ example: 'newemail@example.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: 'Cairo University' })
  @IsOptional()
  @IsString()
  university?: string;

  @ApiPropertyOptional({ description: 'Required only when changing email' })
  @IsOptional()
  @IsString()
  currentPassword?: string;
}
