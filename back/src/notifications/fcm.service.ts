import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

export interface BatchSendResult {
  successCount: number;
  failureCount: number;
  perTokenResults: Array<{
    token: string;
    success: boolean;
    error?: { code: string; message: string };
  }>;
}

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private messaging: admin.messaging.Messaging | null = null;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    const serviceAccountPath = this.configService.get<string>('firebase.serviceAccountPath');
    const serviceAccountJson = this.configService.get<string>('firebase.serviceAccountJson');

    if (serviceAccountJson) {
      try {
        const cred = JSON.parse(serviceAccountJson);
        const app = admin.apps.length
          ? admin.apps[0]!
          : admin.initializeApp({ credential: admin.credential.cert(cred) });
        this.messaging = admin.messaging(app);
        this.logger.log('Firebase initialized from FIREBASE_SERVICE_ACCOUNT_JSON');
      } catch (err) {
        this.logger.error('Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON', err);
      }
    } else if (serviceAccountPath) {
      try {
        const cred = require(serviceAccountPath);
        const app = admin.apps.length
          ? admin.apps[0]!
          : admin.initializeApp({ credential: admin.credential.cert(cred) });
        this.messaging = admin.messaging(app);
        this.logger.log('Firebase initialized from FIREBASE_SERVICE_ACCOUNT_PATH');
      } catch (err) {
        this.logger.error('Failed to load FIREBASE_SERVICE_ACCOUNT_PATH', err);
      }
    } else {
      this.logger.warn(
        'Neither FIREBASE_SERVICE_ACCOUNT_PATH nor FIREBASE_SERVICE_ACCOUNT_JSON is set. Push delivery disabled.',
      );
    }
  }

  async sendBatch(
    tokens: string[],
    payload: { title: string; body: string; data?: Record<string, string> },
  ): Promise<BatchSendResult> {
    if (!this.messaging) {
      this.logger.warn('Firebase messaging not initialized — skipping send');
      return {
        successCount: 0,
        failureCount: tokens.length,
        perTokenResults: tokens.map((t) => ({
          token: t,
          success: false,
          error: { code: 'sdk-not-initialized', message: 'Firebase messaging not initialized' },
        })),
      };
    }

    const BATCH_SIZE = 500;
    let successCount = 0;
    let failureCount = 0;
    const perTokenResults: BatchSendResult['perTokenResults'] = [];

    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const message: admin.messaging.MulticastMessage = {
        tokens: batch,
        notification: { title: payload.title, body: payload.body },
        data: payload.data,
        apns: { payload: { aps: { 'mutable-content': 1 } } },
        android: { notification: { channelId: 'na_academy_default' } },
      };

      let response: admin.messaging.BatchResponse;
      try {
        response = await this.messaging.sendEachForMulticast(message);
      } catch (err) {
        this.logger.error('FCM sendEachForMulticast failed', err);
        for (const t of batch) {
          failureCount++;
          perTokenResults.push({
            token: t,
            success: false,
            error: { code: 'unknown', message: String(err) },
          });
        }
        continue;
      }

      for (let j = 0; j < response.responses.length; j++) {
        const r = response.responses[j];
        const token = batch[j];
        if (r.success) {
          successCount++;
          perTokenResults.push({ token, success: true });
        } else {
          failureCount++;
          const fcmError = r.error;
          const mappedCode = this.mapFcmError(fcmError?.code);
          perTokenResults.push({
            token,
            success: false,
            error: { code: mappedCode, message: fcmError?.message ?? 'Unknown FCM error' },
          });
        }
      }
    }

    return { successCount, failureCount, perTokenResults };
  }

  private mapFcmError(code: string | undefined): string {
    if (!code) return 'unknown';
    if (code.includes('not-registered') || code.includes('registration-token-not-registered'))
      return 'unregistered';
    if (code.includes('invalid-argument') || code.includes('invalid-registration-token'))
      return 'invalid-token';
    if (code.includes('quota-exceeded') || code.includes('message-rate-exceeded'))
      return 'quota-exceeded';
    return 'unknown';
  }
}
