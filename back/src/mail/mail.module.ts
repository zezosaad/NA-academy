import { Module } from '@nestjs/common';
import { MailService } from './mail.service.js';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MailerModule } from '@nestjs-modules/mailer';
import { HandlebarsAdapter } from '@nestjs-modules/mailer/dist/adapters/handlebars.adapter.js';
import { join } from 'path';

@Module({
  imports: [
    MailerModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        transport: {
          host: configService.get<string>('mail.host', 'localhost'),
          port: configService.get<number>('mail.port', 1025),
          secure: configService.get<boolean>('mail.secure', false),
          auth: configService.get<string>('mail.user')
            ? {
                user: configService.get<string>('mail.user'),
                pass: configService.get<string>('mail.pass'),
              }
            : undefined,
          tls: configService.get<any>('mail.tls'),
        },
        defaults: {
          from: configService.get<string>('mail.from', 'no-reply@naacademy.local'),
        },
        template: {
          dir: join(__dirname, 'templates'),
          adapter: new HandlebarsAdapter(),
          options: {
            strict: true,
          },
        },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [MailService],
  exports: [MailService],
})
export class MailModule {}
