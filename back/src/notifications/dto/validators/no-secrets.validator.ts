import {
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
  ValidationOptions,
  registerDecorator,
} from 'class-validator';

const CREDENTIAL_PATTERNS = [
  /\b\d{6}\b.{0,20}(?:code|otp|pin|pass)/i,
  /(?:code|otp|pin|pass).{0,20}\b\d{6}\b/i,
  /eyJ[A-Za-z0-9_-]{10,}/,
  /\bBearer\s+[A-Za-z0-9\-._~+/]+=*/i,
  /password\s*=\s*\S/i,
  /secret\s*=\s*\S/i,
  /api[_-]?key\s*=\s*\S/i,
];

@ValidatorConstraint({ name: 'NoSecretsInBody', async: false })
export class NoSecretsInBodyConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    if (typeof value !== 'string') return true;
    for (const pattern of CREDENTIAL_PATTERNS) {
      if (pattern.test(value)) return false;
    }
    return true;
  }

  defaultMessage(_args: ValidationArguments): string {
    return 'Notification body must not contain credentials, tokens, or secrets';
  }
}

export function NoSecretsInBody(options?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName,
      options,
      validator: NoSecretsInBodyConstraint,
    });
  };
}
