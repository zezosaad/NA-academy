import { Injectable, Logger } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';
import { ConfigService } from '@nestjs/config';
import { join } from 'path';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(
    private readonly mailerService: MailerService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Send the Arabic password-reset email with the 6-digit OTP code and the NA Academy logo.
   * The logo is attached with `cid:logo` so it renders inline (no external host required).
   */
  async sendPasswordResetCodeEmail(
    email: string,
    code: string,
    userName?: string,
  ): Promise<void> {
    const logoPath = join(__dirname, 'templates', 'assets', 'logo.jpeg');

    try {
      await this.mailerService.sendMail({
        to: email,
        subject: 'رمز إعادة تعيين كلمة المرور - NA Academy',
        template: 'password-reset',
        context: {
          code,
          userName: userName || '',
          expiryMinutes: 15,
        },
        attachments: [
          {
            filename: 'logo.jpeg',
            path: logoPath,
            cid: 'logo',
          },
        ],
      });
      this.logger.log(`Password reset code email sent to ${email}`);
    } catch (error) {
      this.logger.error(`Failed to send password reset email to ${email}: ${error}`);
      throw error;
    }
  }
}
