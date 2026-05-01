import { IsIn, IsArray, ArrayMinSize, ArrayMaxSize, IsMongoId, ValidateIf } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type AudienceKind = 'all' | 'user-list' | 'subject';

export class AudienceDto {
  @ApiProperty({ enum: ['all', 'user-list', 'subject'] })
  @IsIn(['all', 'user-list', 'subject'])
  kind!: AudienceKind;

  @ApiPropertyOptional({ type: [String] })
  @ValidateIf((o: AudienceDto) => o.kind === 'user-list')
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(1000)
  @IsMongoId({ each: true })
  userIds?: string[];

  @ApiPropertyOptional()
  @ValidateIf((o: AudienceDto) => o.kind === 'subject')
  @IsMongoId()
  subjectId?: string;
}
