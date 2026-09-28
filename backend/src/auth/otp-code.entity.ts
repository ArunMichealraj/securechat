import { Column, Entity, PrimaryColumn } from 'typeorm';
import { TIMESTAMP } from '../config';

@Entity('otp_codes')
export class OtpCode {
  @PrimaryColumn()
  phone: string;

  // SHA-256 of the code; the plain code is never stored.
  @Column()
  codeHash: string;

  @Column({ type: TIMESTAMP })
  expiresAt: Date;

  @Column({ type: TIMESTAMP })
  sentAt: Date;

  @Column({ default: 0 })
  attempts: number;
}
