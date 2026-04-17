import { ApiProperty } from '@nestjs/swagger';

export class TokenResponseDto {
  @ApiProperty()
  accessToken!: string;

  @ApiProperty()
  refreshToken!: string;

  @ApiProperty()
  user!: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
}
