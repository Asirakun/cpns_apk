import fs from 'node:fs';
import crypto from 'node:crypto';
import sharp from 'sharp';

// A montage of actual Flutter captures, without replacing or repainting UI.
const directory = '../../docs/design/screenshots/v1.2.0';
const names = ['profile-icons', 'preparation', 'history', 'priorities', 'daily', 'navigator'];
const thumbs = await Promise.all(names.map(name => sharp(`${directory}/${name}.png`).resize(260, 600).png().toBuffer()));
await sharp({create: {width: 812, height: 1224, channels: 3, background: '#0A263E'}})
  .composite(thumbs.map((input, i) => ({input, left: 8 + i % 3 * 268, top: 8 + Math.floor(i / 3) * 608})))
  .png().toFile(`${directory}/overview.png`);
const files = fs.readdirSync(directory).filter(n => n.endsWith('.png') && n !== 'overview.png').sort();
const screenshots = await Promise.all(files.map(async name => {
  const p = `${directory}/${name}`, meta = await sharp(p).metadata();
  return {path: `docs/design/screenshots/v1.2.0/${name}`, width: meta.width, height: meta.height,
    sha256: crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')};
}));
if (screenshots.length !== 13) throw new Error('Expected all 13 Flutter capture scenarios');
fs.writeFileSync(`${directory}/screenshots.json`, JSON.stringify({checkedAt: new Date().toISOString(),
  renderer: 'Flutter test engine with actual application font/assets, 2x pixel output',
  viewport: '390x900 dp; light-large 430x900 dp at 1.3x text',
  data: 'MemoryStore fixtures only, labelled DATA UJI; no user database opened',
  deviceTest: false, captures: screenshots.length, montage: 'overview.png', screenshots}, null, 2)+'\n');
console.log(`Created overview and recorded ${screenshots.length} captures.`);
