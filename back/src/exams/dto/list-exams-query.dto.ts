import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationDto } from '../../common/dto/pagination.dto.js';

export class ListExamsQueryDto extends PaginationDto {
  @ApiPropertyOptional({ example: '507f1f77bcf86cd799439011' })
  @IsOptional()
  @IsString()
  subjectId?: string;
}
