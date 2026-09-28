import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { OtpCode } from './otp-code.entity';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';

@Module({
  imports: [TypeOrmModule.forFeature([OtpCode]), UsersModule],
  providers: [AuthService],
  controllers: [AuthController],
})
export class AuthModule {}
