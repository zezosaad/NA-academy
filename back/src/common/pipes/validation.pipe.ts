import { ValidationPipe, ValidationPipeOptions } from '@nestjs/common';

export const validationPipeOptions: ValidationPipeOptions = {
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true,
  transformOptions: {
    enableImplicitConversion: true,
  },
};

export const globalValidationPipe = new ValidationPipe(validationPipeOptions);
