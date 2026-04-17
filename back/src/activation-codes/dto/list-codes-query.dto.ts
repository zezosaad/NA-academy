import { IsOptional, IsEnum } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
import { CodeStatus } from '../schemas/subject-code.schema.js';

export class ListCodesQueryDto extends PaginationDto {
  @ApiPropertyOptional({ enum: CodeStatus })
  @IsOptional()
  @IsEnum(CodeStatus)
  status?: CodeStatus;
}
