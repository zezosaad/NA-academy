import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';
import { globalValidationPipe } from './common/pipes/validation.pipe.js';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter.js';
import { ResponseTransformInterceptor } from './common/interceptors/response-transform.interceptor.js';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Global prefix
  app.setGlobalPrefix('api/v1');

  // CORS
  app.enableCors();

  // Global pipes, filters, interceptors
  app.useGlobalPipes(globalValidationPipe);
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new ResponseTransformInterceptor());

  // Swagger
  const swaggerConfig = new DocumentBuilder()
    .setTitle('NA-Academy API')
    .setDescription('NA-Academy Backend Platform API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  // Shutdown hooks
  app.enableShutdownHooks();

  const configService = app.get(ConfigService);
  const port = configService.get<number>('port') || 3000;

  await app.listen(port);
  logger.log(`Application running on port ${port}`);
  logger.log(`Swagger docs at http://localhost:${port}/api/docs`);
}

bootstrap();
