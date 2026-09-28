import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { config, isPostgres } from './config';
import { User } from './users/user.entity';
import { Message } from './chat/message.entity';
import { OtpCode } from './auth/otp-code.entity';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ChatModule } from './chat/chat.module';
import { HealthController } from './health.controller';

const entities = [User, Message, OtpCode];

@Module({
  imports: [
    TypeOrmModule.forRoot(
      isPostgres
        ? { type: 'postgres', url: config.databaseUrl, entities, synchronize: config.dbSync }
        : { type: 'better-sqlite3', database: config.sqlitePath, entities, synchronize: config.dbSync },
    ),
    JwtModule.register({ global: true, secret: config.jwtSecret, signOptions: { expiresIn: '30d' } }),
    UsersModule,
    AuthModule,
    ChatModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
