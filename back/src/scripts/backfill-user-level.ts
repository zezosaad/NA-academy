import mongoose from 'mongoose';

const DEFAULT_LEVEL = 'secondary_3';

async function bootstrap() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/na-academy';

  await mongoose.connect(uri);
  console.log(`Connected to ${uri}`);

  const result = await mongoose.connection
    .collection('users')
    .updateMany(
      { $or: [{ level: { $exists: false } }, { level: null }] },
      { $set: { level: DEFAULT_LEVEL } },
    );

  console.log(
    `Backfilled level=${DEFAULT_LEVEL} on ${result.modifiedCount} user(s) (matched ${result.matchedCount}).`,
  );

  await mongoose.disconnect();
  process.exit(0);
}

bootstrap().catch((err) => {
  console.error('Failed to backfill user levels:', err);
  process.exit(1);
});
