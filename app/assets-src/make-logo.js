// Builds the AB Chat logo: the AB monogram in white inside a blue chat bubble.
// Run: node make-logo.js   (needs `sharp`; run with NODE_PATH pointing at a folder that has it)
const sharp = require('sharp');
const path = require('path');

const here = __dirname;
const out = (name) => path.join(here, '..', 'assets', name);
const SIZE = 1024;

// Chat bubble: circle with a tail at the bottom-left, blue gradient.
const bubbleSvg = (bg) => `
<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#3B8CFF"/>
      <stop offset="1" stop-color="#1557B8"/>
    </linearGradient>
  </defs>
  ${bg ? `<rect width="1024" height="1024" fill="${bg}"/>` : ''}
  <path d="M512 92c-226 0-410 176-410 394 0 84 27 162 74 226L126 902l206-62c54 28 116 44 180 44 226 0 410-176 410-398S738 92 512 92z" fill="url(#g)"/>
</svg>`;

async function whiteMonogram(targetWidth) {
  // Turn the red-on-white logo into white-on-transparent using darkness as alpha.
  const { data, info } = await sharp(path.join(here, 'ab-original.png'))
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  const px = Buffer.alloc(info.width * info.height * 4);
  for (let i = 0; i < info.width * info.height; i++) {
    const [r, g, b, a] = [data[i * 4], data[i * 4 + 1], data[i * 4 + 2], data[i * 4 + 3]];
    const lum = 0.299 * r + 0.587 * g + 0.114 * b;
    const alpha = Math.min(255, Math.max(0, (255 - lum) * 1.45)) * (a / 255);
    px.set([255, 255, 255, Math.round(alpha < 20 ? 0 : alpha)], i * 4);
  }
  return sharp(px, { raw: { width: info.width, height: info.height, channels: 4 } })
    .trim({ threshold: 10 })
    .resize({ width: targetWidth })
    .png()
    .toBuffer();
}

async function logo({ bg, scale = 1 }) {
  const mono = await whiteMonogram(Math.round(500 * scale));
  const meta = await sharp(mono).metadata();
  // Circle centre of the bubble is (512, 486).
  const bubble = await sharp(Buffer.from(bubbleSvg(bg))).png().toBuffer();
  return sharp(bubble)
    .composite([{ input: mono, left: Math.round(512 - meta.width / 2), top: Math.round(486 - meta.height / 2) }])
    .png();
}

(async () => {
  // In-app logo and legacy launcher icon: transparent background.
  await (await logo({})).toFile(out('logo.png'));
  // iOS / store icon: no transparency allowed.
  await (await logo({ bg: '#FFFFFF' })).toFile(out('icon-ios.png'));
  // Android adaptive icon foreground: shrink into the 66% safe zone.
  const fg = await sharp(await (await logo({})).toBuffer()).resize(640, 640).toBuffer();
  await sharp({ create: { width: SIZE, height: SIZE, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: fg, left: 192, top: 192 }])
    .png()
    .toFile(out('icon-foreground.png'));
  // Link-preview image (WhatsApp, Teams, Facebook...): 1200x630, logo + name on blue.
  const preview = await sharp(await (await logo({})).toBuffer()).resize(360, 360).toBuffer();
  const card = `
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#2F8CFF"/>
      <stop offset="1" stop-color="#1557B8"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <circle cx="290" cy="315" r="215" fill="#FFFFFF"/>
  <text x="560" y="300" font-family="Segoe UI, Arial, sans-serif" font-size="110" font-weight="700" fill="#FFFFFF">AB Chat</text>
  <text x="564" y="380" font-family="Segoe UI, Arial, sans-serif" font-size="42" fill="#DCEBFF">Private messaging for everyone</text>
</svg>`;
  await sharp(Buffer.from(card))
    .composite([{ input: preview, left: 110, top: 135 }])
    .png()
    .toFile(path.join(here, '..', 'web', 'og-image.png'));

  console.log('logo written');
})();
