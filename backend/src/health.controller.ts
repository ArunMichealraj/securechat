import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  // The app calls this to check the server address typed on the login screen.
  @Get('health')
  health() {
    return { ok: true, name: 'securechat' };
  }
}
