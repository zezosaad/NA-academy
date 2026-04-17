import { IsEnum, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum ExportFormat {
  CSV = 'csv',
  XLSX = 'xlsx',
}

export class BatchExportQueryDto {
  @ApiProperty({ enum: ExportFormat, example: ExportFormat.XLSX })
  @IsEnum(ExportFormat)
  @IsNotEmpty()
  format!: ExportFormat;
}
