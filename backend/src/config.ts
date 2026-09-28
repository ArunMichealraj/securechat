import 'dotenv/config';

const isProduction = process.env.NODE_ENV === 'production';
export const isPostgres = process.env.DB_TYPE === 'postgres';

export const config = {
  port: Number(process.env.PORT ?? 3000),
  isProduction,
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret-change-me',
  // Returns the OTP in the API response so people can log in without an SMS provider.
  // On by default in development; in production only while EXPOSE_OTP=true (turn off once SMS is set up).
  exposeOtp: process.env.EXPOSE_OTP ? process.env.EXPOSE_OTP === 'true' : !isProduction,
  dbSync: (process.env.DB_SYNC ?? 'true') === 'true',
  sqlitePath: process.env.SQLITE_PATH ?? 'data/dev.sqlite',
  databaseUrl: process.env.DATABASE_URL,
};

if (isProduction && config.jwtSecret === 'dev-secret-change-me') {
  throw new Error('Set JWT_SECRET in production');
}

// Column type for nullable timestamps that works on both SQLite and Postgres.
export const TIMESTAMP = isPostgres ? 'timestamptz' : 'datetime';
