import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module.js';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import * as fs from 'fs';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { logger: false });
  
  const swaggerConfig = new DocumentBuilder()
    .setTitle('NA-Academy API')
    .setDescription('NA-Academy Backend Platform API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  
  fs.writeFileSync('./swagger.json', JSON.stringify(document, null, 2));
  console.log('Swagger JSON dynamically generated inside ./swagger.json');
  
  await app.close();
  process.exit(0);
}

bootstrap().catch(err => {
  console.error('Failed to generate Swagger JSON:', err);
  process.exit(1);
});
