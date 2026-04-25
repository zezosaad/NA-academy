import { Injectable, Logger } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(
    private readonly mailerService: MailerService,
    private readonly configService: ConfigService,
  ) {}

  async sendPasswordResetEmail(email: string, token: string): Promise<void> {
    const appScheme = `naacademy://auth/reset?token=${token}`;
    const universalLink = `https://naacademy.app/reset?token=${token}`;

    try {
      await this.mailerService.sendMail({
        to: email,
        subject: 'Reset your NA-Academy password',
        template: 'password-reset',
        context: {
          appScheme,
          universalLink,
        },
      });
      this.logger.log(`Password reset email sent to ${email}`);
    } catch (error) {
      this.logger.error(`Failed to send password reset email to ${email}: ${error}`);
      throw error;
    }
  }
}
