import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import sharp from 'sharp';

// Motioncraft's Windows CLI loses quotes around inline props and its qa-full
// needs Python. Keep the same debug-pixel rules, use a props FILE, and inspect
// every decoded frame with Node/sharp instead. No system tools are installed.
const cli = path.resolve('node_modules/@remotion/cli/remotion-cli.js');
const ffmpeg = path.resolve('node_modules/@remotion/compositor-win32-x64-msvc/ffmpeg.exe');
function run(exe, args) {
  const r = spawnSync(exe, args, {stdio: 'inherit'});
  if (r.error || r.status !== 0) throw r.error || new Error(`${path.basename(exe)} exited ${r.status}`);
}
fs.mkdirSync('out/qa-debug', {recursive: true});
fs.writeFileSync('out/qa-props.json', JSON.stringify({mcDebug: true}));
run(process.execPath, [cli, 'render', 'src/index.tsx', 'Intro', 'out/intro-debug.mp4', '--props=out/qa-props.json', '--scale=0.25', '--concurrency=2', '--gl=angle', '--crf=1', '--muted']);
run(ffmpeg, ['-hide_banner', '-loglevel', 'error', '-y', '-i', 'out/intro-debug.mp4', 'out/qa-debug/frame-%03d.png']);
const debug = fs.readdirSync('out/qa-debug').filter(n => n.endsWith('.png')).sort();
const actual = fs.readdirSync('out/decoded').filter(n => n.endsWith('.png')).sort();
if (debug.length !== 96 || actual.length !== 96) throw new Error('Incomplete decoded frame sequence');
const issues = [];
for (const [f, name] of debug.entries()) {
  const {data, info} = await sharp(path.join('out/qa-debug', name)).removeAlpha().raw().toBuffer({resolveWithObject: true});
  let textOverlap = 0, blockOverlap = 0, edge = 0;
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
    const i = (y * info.width + x) * info.channels;
    const [r, g, b] = data.subarray(i, i + 3);
    if (r > 200 && g < 100 && b < 100) textOverlap++;
    if (g > 200 && r < 110 && b < 110) blockOverlap++;
    if ((x < 12 || x >= info.width - 12 || y < 20 || y >= info.height - 20) && r > 200 && g < 170 && b < 170) edge++;
  }
  if (textOverlap > 9 || blockOverlap > 36 || edge > 9) issues.push({frame: f, textOverlap, blockOverlap, edge});
}
let readableFrames = 0;
for (const [f, name] of actual.entries()) {
  const {data, info} = await sharp(path.join('out/decoded', name)).removeAlpha().raw().toBuffer({resolveWithObject: true});
  if (info.width !== 720 || info.height !== 1280) throw new Error('Unexpected decoded video dimensions');
  let textPixels = 0, unsafeTextPixels = 0;
  for (let y = 700; y < 860; y++) for (let x = 0; x < info.width; x++) {
    const i = (y * info.width + x) * info.channels;
    if (data[i] > 140 && data[i + 1] > 175 && data[i + 2] > 130) {
      textPixels++;
      if (x < 48 || x > 672) unsafeTextPixels++;
    }
  }
  if (unsafeTextPixels > 8) issues.push({frame: f, unsafeTextPixels});
  if (f >= 40 && textPixels < 200) issues.push({frame: f, missingExpectedText: true});
  if (f >= 40 && textPixels >= 200) readableFrames++;
}
const picks = [0, 10, 20, 30, 40, 50, 65, 80, 95];
const thumbs = await Promise.all(picks.map(i => sharp(path.join('out/decoded', actual[i])).resize(180, 320).png().toBuffer()));
await sharp({create: {width: 564, height: 984, channels: 3, background: '#0A263E'}})
  .composite(thumbs.map((input, i) => ({input, left: 6 + i % 3 * 186, top: 6 + Math.floor(i / 3) * 326})))
  .png().toFile('../../docs/design/v1.2.0/intro/qa-contact-sheet.png');
for (const i of [20, 48, 95]) fs.copyFileSync(path.join('out/decoded', actual[i]), `../../docs/design/v1.2.0/intro/frame-${i}.png`);
const report = {checkedAt: new Date().toISOString(), video: 'docs/design/v1.2.0/intro/papercut-intro.mp4', decodedFrames: actual.length,
  debugFrames: debug.length, readableHoldFrames: readableFrames, issues, pass: issues.length === 0,
  method: 'Motioncraft debug color thresholds + all decoded final video frames + text-region safe margins. Props file fixes Windows quoting.',
  audio: 'Intentionally silent app intro; voice/music loudness tests are not applicable.',
  limitations: 'No OCR/Python available. Pixel checks are heuristics; contact sheet and full-size frames must also be visually reviewed. Not a device playback test.'};
fs.writeFileSync('../../docs/design/v1.2.0/intro/qa.json', JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
if (!report.pass) process.exitCode = 1;
