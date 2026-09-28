import { BadRequestException, HttpException, HttpStatus, Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { createHash, randomInt, timingSafeEqual } from 'crypto';
import { config } from '../config';
import { UsersService } from '../users/users.service';
import { OtpCode } from './otp-code.entity';

const OTP_TTL_MS = 5 * 60_000;
const RESEND_COOLDOWN_MS = 30_000;
const MAX_ATTEMPTS = 5;

const hash = (code: string) => createHash('sha256').update(code).digest('hex');

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(OtpCode) private readonly otps: Repository<OtpCode>,
    private readonly users: UsersService,
    private readonly jwt: JwtService,
  ) {}

  async requestOtp(phone: string): Promise<{ sent: true; devCode?: string }> {
    const existing = await this.otps.findOneBy({ phone });
    if (existing && Date.now() - new Date(existing.sentAt).getTime() < RESEND_COOLDOWN_MS) {
      throw new HttpException('Please wait 30 seconds before requesting a new code', HttpStatus.TOO_MANY_REQUESTS);
    }

    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    const now = new Date();
    await this.otps.save({ phone, codeHash: hash(code), sentAt: now, expiresAt: new Date(now.getTime() + OTP_TTL_MS), attempts: 0 });

    // TODO: send via an SMS provider (Twilio, MSG91, Firebase Phone Auth) in production.
    this.logger.log(`OTP for ${phone}: ${code}`);
    return config.exposeOtp ? { sent: true, devCode: code } : { sent: true };
  }

  async verifyOtp(phone: string, code: string) {
    const otp = await this.otps.findOneBy({ phone });
    if (!otp || new Date(otp.expiresAt).getTime() < Date.now()) {
      throw new BadRequestException('Code expired. Request a new one.');
    }
    if (otp.attempts >= MAX_ATTEMPTS) {
      throw new BadRequestException('Too many attempts. Request a new code.');
    }

    const ok = timingSafeEqual(Buffer.from(hash(code)), Buffer.from(otp.codeHash));
    if (!ok) {
      await this.otps.update(phone, { attempts: otp.attempts + 1 });
      throw new BadRequestException('Wrong code');
    }

    await this.otps.delete(phone);
    const user = await this.users.findOrCreateByPhone(phone);
    return { token: this.jwt.sign({ sub: user.id }), user };
  }
}
