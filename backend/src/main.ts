import 'reflect-metadata';
import { mkdirSync } from 'fs';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { config } from './config';

async function bootstrap() {
  mkdirSync('data', { recursive: true });
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  // 0.0.0.0 so phones on the same Wi-Fi can reach it via your PC's LAN IP.
  await app.listen(config.port, '0.0.0.0');
  console.log(`SecureChat API + WebSocket on http://0.0.0.0:${config.port}`);
}
bootstrap();
