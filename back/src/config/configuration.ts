function parseCsvEnv(value: string | undefined): string[] | undefined {
  if (value == null || value.trim() === '') return undefined;
  const parts = value
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  return parts.length ? parts : undefined;
}

export default () => ({
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  cors: {
    /** Comma-separated browser origins (e.g. https://naacademy.tech). If unset, all origins are allowed. */
    origins: parseCsvEnv(process.env.CORS_ORIGINS),
  },

  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/na-academy',
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'change-me-in-production',
    accessExpiration: process.env.JWT_ACCESS_EXPIRATION || '15m',
    refreshExpiration: process.env.JWT_REFRESH_EXPIRATION || '7d',
  },

  exam: {
    hmacSecret: process.env.EXAM_HMAC_SECRET || 'change-me-in-production',
  },

  upload: {
    maxVideoSizeMb: parseInt(process.env.MAX_VIDEO_SIZE_MB || '2048', 10),
    maxImageSizeMb: parseInt(process.env.MAX_IMAGE_SIZE_MB || '20', 10),
  },

  rateLimit: {
    activationRateLimit: parseInt(process.env.ACTIVATION_RATE_LIMIT || '5', 10),
    activationRateWindowMinutes: parseInt(process.env.ACTIVATION_RATE_WINDOW_MINUTES || '15', 10),
  },

  gridfs: {
    videoChunkSize: parseInt(process.env.GRIDFS_VIDEO_CHUNK_SIZE || '1048576', 10),
    chatChunkSize: parseInt(process.env.GRIDFS_CHAT_CHUNK_SIZE || '261120', 10),
  },

  mail: {
    host: process.env.MAIL_HOST || 'localhost',
    port: parseInt(process.env.MAIL_PORT || '1025', 10),
    secure: process.env.MAIL_SECURE === 'true',
    user: process.env.MAIL_USER || '',
    pass: process.env.MAIL_PASS || '',
    from: process.env.MAIL_FROM || 'no-reply@naacademy.local',
    /** HTTPS base for password-reset universal links (no trailing slash). */
    publicResetHost:
      process.env.MAIL_PUBLIC_RESET_HOST || 'https://naacademy.tech',
    appSchemeBase: process.env.MAIL_APP_SCHEME_BASE || 'naacademy://auth',
    tls: {
      rejectUnauthorized: process.env.MAIL_TLS_REJECT_UNAUTHORIZED !== 'false',
    },
  },

  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    serviceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH || '',
    serviceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '',
  },
});
