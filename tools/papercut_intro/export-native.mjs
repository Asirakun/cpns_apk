import fs from 'node:fs';
import {spring,interpolate} from 'remotion';
import crypto from 'node:crypto';
const directory='out/hd/mark-frames';
const frames=fs.readdirSync(directory).filter(n=>n.endsWith('.png')).sort();
if(frames.length!==96)throw new Error('Incomplete GPU frame sequence');
const target='../../assets/intro/papercut-mark-hd.png';
fs.copyFileSync(`${directory}/${frames[95]}`,target);
const timing={fps:30,frames:96,durationMs:3200,
  mark:Array.from({length:96},(_,frame)=>spring({frame,fps:30,config:{damping:20,stiffness:90,mass:.9}})),
  title:Array.from({length:96},(_,frame)=>interpolate(frame,[21,33],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'})),
  subtitle:Array.from({length:96},(_,frame)=>interpolate(frame,[29,40],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'})),
};
fs.writeFileSync('../../assets/intro/remotion-motion.json',JSON.stringify(timing)+'\n');
const result={asset:'assets/intro/papercut-mark-hd.png',width:1080,height:1080,format:'lossless PNG with transparent alpha',
  bytes:fs.statSync(target).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(target)).digest('hex'),
  source:'Final frame from the verified RTX 3050 Remotion render, without resizing',
  timeline:'assets/intro/remotion-motion.json',fps:30,frames:96,durationMs:3200,
  playback:'Flutter applies exported Remotion transforms/opacity to a single HD PNG at native display refresh rate; text and full-viewport background are native.'};
fs.writeFileSync('../../docs/design/v1.2.1/intro/asset-metadata.json',JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result,null,2));
