import {
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
  registerDecorator,
  ValidationOptions,
} from 'class-validator';

const KEY_REGEX = /^[a-zA-Z][a-zA-Z0-9_]{0,31}$/;
const MAX_PAYLOAD_BYTES = 4096;

@ValidatorConstraint({ name: 'ValidateData', async: false })
export class ValidateDataConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    if (value === null || value === undefined) return true;
    if (typeof value !== 'object' || Array.isArray(value)) return false;

    const entries = Object.entries(value as Record<string, unknown>);

    for (const [key, val] of entries) {
      if (!KEY_REGEX.test(key)) return false;
      if (typeof val !== 'string') return false;
    }

    let totalBytes = 0;
    for (const [key, val] of entries) {
      totalBytes += Buffer.byteLength(key, 'utf8') + Buffer.byteLength(val as string, 'utf8');
    }

    return totalBytes <= MAX_PAYLOAD_BYTES;
  }

  defaultMessage(_args: ValidationArguments): string {
    return 'data keys must match /^[a-zA-Z][a-zA-Z0-9_]{0,31}$/, all values must be strings, and total payload must be ≤ 4 KB';
  }
}

export function ValidateData(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName,
      options: validationOptions,
      constraints: [],
      validator: ValidateDataConstraint,
    });
  };
}
