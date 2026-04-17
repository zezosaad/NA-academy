import { IsEnum, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { UserStatus } from '../schemas/user.schema.js';

export class UpdateStatusDto {
  @ApiProperty({ enum: UserStatus, example: UserStatus.SUSPENDED })
  @IsEnum(UserStatus)
  @IsNotEmpty()
  status!: UserStatus;
}
