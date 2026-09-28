import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { IsString, Matches } from 'class-validator';
import { normalizePhone } from '../common/phone';
import { AuthService } from './auth.service';

class RequestOtpDto {
  @IsString()
  phone: string;
}

class VerifyOtpDto {
  @IsString()
  phone: string;

  @Matches(/^\d{6}$/, { message: 'Code must be 6 digits' })
  code: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('request-otp')
  @HttpCode(200)
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.auth.requestOtp(normalizePhone(dto.phone));
  }

  @Post('verify-otp')
  @HttpCode(200)
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.auth.verifyOtp(normalizePhone(dto.phone), dto.code);
  }
}
