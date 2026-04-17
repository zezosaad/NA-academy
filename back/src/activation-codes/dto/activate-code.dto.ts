import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ActivateCodeDto {
  @ApiProperty({ example: 'KR7NV3PXHM4T' })
  @IsString()
  @IsNotEmpty()
  code!: string;
}
