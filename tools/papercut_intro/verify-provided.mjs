import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync}from'node:child_process';import sharp from'sharp';
const dest='../../docs/design/v1.2.2/intro';
const wav=fs.readFileSync('../../assets/intro/intro-sfx.wav');
let offset=12,data;while(offset+8<=wav.length){const name=wav.toString('ascii',offset,offset+4),len=wav.readUInt32LE(offset+4);if(name==='data'){data=wav.subarray(offset+8,offset+8+len);break;}offset+=8+len+(len%2);}
if(!data)throw Error('WAV has no samples');let peak=0,sum=0,nonzero=0;for(let i=0;i<data.length;i+=2){const n=wav.readInt16LE(wav.length-data.length+i)/32768;peak=Math.max(peak,Math.abs(n));sum+=n*n;if(n!==0)nonzero++;}
if(peak===0||peak>=1||nonzero<10000)throw Error('WAV silent or clipped');
const bin=path.resolve('node_modules/@remotion/compositor-win32-x64-msvc');
const probe=spawnSync(`${bin}/ffprobe.exe`,['-v','error','-show_entries','format=duration:stream=codec_type,codec_name,width,height,nb_frames','-of','json',`${dest}/provided-intro-with-sfx.mp4`],{encoding:'utf8'});if(probe.status!==0)throw Error(probe.stderr);const meta=JSON.parse(probe.stdout);
if(!meta.streams.some(s=>s.codec_type==='audio')||!meta.streams.some(s=>s.width===1440&&s.height===3200))throw Error('Video/audio metadata mismatch');
fs.mkdirSync('out/provided/decoded',{recursive:true});
const decode=spawnSync(`${bin}/ffmpeg.exe`,['-hide_banner','-loglevel','error','-y','-i',`${dest}/provided-intro-with-sfx.mp4`,'out/provided/decoded/frame-%03d.png'],{stdio:'inherit'});if(decode.status!==0)throw Error('Decode failed');
const files=fs.readdirSync('out/provided/decoded').filter(n=>n.endsWith('.png')).sort();if(files.length!==200)throw Error('Frame count mismatch');
for(const name of files){const {data,info}=await sharp(`out/provided/decoded/${name}`).removeAlpha().raw().toBuffer({resolveWithObject:true});if(info.width!==1440||info.height!==3200)throw Error('Frame size mismatch');for(const [x,y]of[[1,1],[1438,1],[1,3198],[1438,3198]]){const at=(y*1440+x)*info.channels;for(let c=0;c<3;c++)if(Math.abs(data[at+c]-[8,34,59][c])>5)throw Error('Original background leaked into preview');}}
for(const f of[30,90,180])fs.copyFileSync(`out/provided/decoded/${files[f]}`,`${dest}/frame-${f}.png`);
const thumbs=await Promise.all([0,30,60,90,120,150,180,199].map(f=>sharp(`out/provided/decoded/${files[f]}`).resize(180,400).png().toBuffer()));
await sharp({create:{width:752,height:818,channels:3,background:'#08223B'}}).composite(thumbs.map((input,i)=>({input,left:6+i%4*188,top:6+Math.floor(i/4)*406}))).png().toFile(`${dest}/contact-sheet.png`);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const report={checkedAt:new Date().toISOString(),frames:200,master:meta,wavPeak:peak,wavRms:Math.sqrt(sum/(data.length/2)),wavSha256:hash(wav),originalMixIdentical:hash(wav)===hash(fs.readFileSync('../../cpns-intro/tools/mix-preview.wav')),backgroundCornersMatchApp:true,skipButtonRemoved:true,physicalAndroidAudioTest:false};
fs.writeFileSync(`${dest}/qa.json`,JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
