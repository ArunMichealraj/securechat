import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  // The app calls this to check the server address typed on the login screen.
  @Get('health')
  health() {
    // RENDER_GIT_COMMIT is set by Render; it shows which version is deployed.
    return { ok: true, name: 'abchat', version: process.env.RENDER_GIT_COMMIT?.slice(0, 7) ?? 'local' };
  }
}
