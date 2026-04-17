export default () => ({
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

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
    activationRateWindowMinutes: parseInt(
      process.env.ACTIVATION_RATE_WINDOW_MINUTES || '15',
      10,
    ),
  },

  gridfs: {
    videoChunkSize: parseInt(process.env.GRIDFS_VIDEO_CHUNK_SIZE || '1048576', 10),
    chatChunkSize: parseInt(process.env.GRIDFS_CHAT_CHUNK_SIZE || '261120', 10),
  },
});
