import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const frames = fs.readdirSync('out/hd/mark-frames').filter(n => n.endsWith('.png')).sort().map(n => path.join('out/hd/mark-frames', n));
if (frames.length !== 96) throw new Error(`Expected 96 Remotion frames, got ${frames.length}`);
const delay = frames.map((_, i) => i % 3 === 2 ? 34 : 33);
// Optional lossless image-sequence preview only; the APK uses the much smaller
// GPU-rendered PNG and exported native transform timeline.
const out = path.resolve('out/hd/papercut-mark-lossless.webp');
await sharp(frames, {join: {animated: true}}).webp({lossless: true, quality: 100, alphaQuality: 100, loop: 1, delay, effort: 5}).toFile(out);
const meta = await sharp(out, {animated: true}).metadata();
// The encoder coalesces identical hold frames, preserving their total delay.
if (meta.pages < 2 || meta.pages > 96 || meta.pageHeight !== 1080 || meta.width !== 1080 || !meta.hasAlpha || meta.delay.reduce((a, b) => a + b, 0) !== 3200) throw new Error('Unexpected intro animation dimensions/duration');
const result = {source: 'Remotion IntroMark 96 frames / 30 fps', asset: 'out/hd/papercut-mark-lossless.webp', width: meta.width, height: meta.pageHeight,
  sourceFrames: 96, encodedFrames: meta.pages, durationMs: meta.delay.reduce((a, b) => a + b, 0), loop: meta.loop, bytes: fs.statSync(out).size, silent: true,
  lossless:true,alpha:true,text:'Native Flutter, at device pixel ratio',background:'Native full-viewport PaperBackdrop and active theme, no baked video rectangle'};
fs.writeFileSync('out/hd/webp-metadata.json', JSON.stringify(result, null, 2));
console.log(JSON.stringify(result, null, 2));
