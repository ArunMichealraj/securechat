import { BadRequestException } from '@nestjs/common';

// Normalizes to E.164 (+<country code><number>), e.g. "+91 98765 43210" -> "+919876543210".
export function normalizePhone(input: string): string {
  const digits = input.replace(/[^\d+]/g, '');
  const phone = digits.startsWith('+') ? '+' + digits.slice(1).replace(/\+/g, '') : '+' + digits;
  if (!/^\+\d{8,15}$/.test(phone)) {
    throw new BadRequestException('Phone number must include country code, e.g. +919876543210');
  }
  return phone;
}
