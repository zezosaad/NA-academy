import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ApiResponseDto<T> {
  @ApiProperty()
  data: T;

  @ApiPropertyOptional()
  total?: number;

  @ApiPropertyOptional()
  page?: number;

  @ApiPropertyOptional()
  limit?: number;

  constructor(data: T, meta?: { total?: number; page?: number; limit?: number }) {
    this.data = data;
    if (meta) {
      this.total = meta.total;
      this.page = meta.page;
      this.limit = meta.limit;
    }
  }
}
