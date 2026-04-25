import { IsMongoId, IsDefined, registerDecorator, ValidatorConstraint, ValidatorConstraintInterface, ValidationArguments } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

@ValidatorConstraint({ name: 'isStringOrStringArray', async: false })
export class IsStringOrStringArrayConstraint implements ValidatorConstraintInterface {
  validate(value: any, _validationArguments?: ValidationArguments): boolean {
    if (typeof value === 'string') return true;
    if (Array.isArray(value) && value.every((item: any) => typeof item === 'string')) return true;
    return false;
  }

  defaultMessage(_validationArguments?: ValidationArguments): string {
    return 'value must be a string or an array of strings';
  }
}

export function IsStringOrStringArray() {
  return function (object: object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName,
      options: { message: 'value must be a string or an array of strings' },
      constraints: [],
      validator: IsStringOrStringArrayConstraint,
    });
  };
}

export class SaveAnswerDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  questionId!: string;

  @ApiProperty({
    example: 'A',
    description: 'A single answer value or an array of values for multi-select',
  })
  @IsDefined()
  @IsStringOrStringArray()
  value!: string | string[];
}