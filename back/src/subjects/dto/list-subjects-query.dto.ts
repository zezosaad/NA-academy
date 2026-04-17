import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class ListSubjectsQueryDto extends PaginationDto {
  @ApiPropertyOptional({ example: 'Mathematics' })
  @IsOptional()
  @IsString()
  category?: string;
}
