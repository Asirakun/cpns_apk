import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import sharp from 'sharp';
import {selectComposition,renderFrames} from '@remotion/renderer';
import {openVerifiedGpuBrowser} from './gpu-browser.mjs';

const destination='../../docs/design/v1.2.1/intro';
const ffmpeg=path.resolve('node_modules/@remotion/compositor-win32-x64-msvc/ffmpeg.exe');
fs.mkdirSync('out/hd/decoded',{recursive:true});
const decode=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y','-i',`${destination}/papercut-intro-qhd.mp4`,'out/hd/decoded/frame-%03d.png'],{stdio:'inherit'});
if(decode.error||decode.status!==0)throw decode.error||new Error('Cannot decode final NVENC video');
const {browser}=await openVerifiedGpuBrowser();
try {
 const common={serveUrl:path.resolve('out/hd/bundle'),puppeteerInstance:browser,inputProps:{mcDebug:true},logLevel:'error',concurrency:2};
 const composition=await selectComposition({...common,id:'Intro'});
 await renderFrames({...common,composition,scale:.25,imageFormat:'png',outputDir:'out/hd/debug-verified',onStart:()=>{},onFrameUpdate:()=>{}});
}finally{await browser.close({silent:true});}
const list=p=>fs.readdirSync(p).filter(n=>n.endsWith('.png')).sort().map(n=>path.join(p,n));
const actual=list('out/hd/decoded'),debug=list('out/hd/debug-verified'),mark=list('out/hd/mark-frames');
if(actual.length!==96||debug.length!==96||mark.length!==96)throw new Error('Incomplete frame sets');
const issues=[];let debugPresent=false;
for(let f=0;f<96;f++){
 const {data,info}=await sharp(debug[f]).removeAlpha().raw().toBuffer({resolveWithObject:true});
 let red=0,green=0,overlap=0;
 for(let i=0;i<data.length;i+=info.channels){const [r,g,b]=data.subarray(i,i+3);if(r>100&&g<100&&b<100)red++;if(g>70&&r<60&&b<80)green++;if(r>200&&g<100&&b<100)overlap++;}
 if(f===65)debugPresent=red>200&&green>200;
 if(overlap>9)issues.push({frame:f,textOverlap:overlap});
 const raw=await sharp(mark[f]).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 if(raw.info.width!==1080||raw.info.height!==1080)issues.push({frame:f,markSize:true});
 for(const [x,y]of[[0,0],[1079,0],[0,1079],[1079,1079]])if(raw.data[(y*1080+x)*4+3]!==0)issues.push({frame:f,opaqueMarkEdge:true});
 const video=await sharp(actual[f]).removeAlpha().raw().toBuffer({resolveWithObject:true});
 if(video.info.width!==1440||video.info.height!==3200)throw new Error('Wrong master resolution');
 let text=0,unsafe=0;
 for(let y=1950;y<2160;y++)for(let x=0;x<1440;x++){
  const i=(y*1440+x)*video.info.channels;
  if(video.data[i]>200&&video.data[i+1]>190&&video.data[i+2]>150){text++;if(x<96||x>1344)unsafe++;}
 }
 if(f>=40&&text<1000)issues.push({frame:f,missingTitle:true});
 if(unsafe>8)issues.push({frame:f,unsafeText:unsafe});
}
if(!debugPresent)issues.push({debugMaskNotPresent:true});
const png=await sharp('../../assets/intro/papercut-mark-hd.png').ensureAlpha().raw().toBuffer();
const final=await sharp(mark[95]).ensureAlpha().raw().toBuffer();
if(!png.equals(final))issues.push({nativePngNotExactGpuFrame:true});
const picks=[0,10,20,30,40,50,65,80,95];
const thumbs=await Promise.all(picks.map(i=>sharp(actual[i]).resize(180,400).png().toBuffer()));
await sharp({create:{width:564,height:1224,channels:3,background:'#08223B'}})
 .composite(thumbs.map((input,i)=>({input,left:6+i%3*186,top:6+Math.floor(i/3)*406}))).png().toFile(`${destination}/qa-contact-sheet.png`);
for(const i of[20,48,95])fs.copyFileSync(actual[i],`${destination}/frame-${i}.png`);
const report={checkedAt:new Date().toISOString(),videoResolution:[1440,3200],videoFrames:96,debugFrames:96,transparentMarkFrames:96,
 nativeAssetResolution:[1080,1080],nativeAssetExactlyMatchesGpuFrame:true,debugMasksVerified:debugPresent,
 issues,pass:issues.length===0,method:'All decoded final NVENC video frames + verified debug masks + transparent mark corners + exact PNG/frame pixels',
 limitations:'Pixel checks are heuristics; visual contact-sheet/full-size review and Flutter aspect-ratio/background tests are separate. Not a physical Android playback test.'};
fs.writeFileSync(`${destination}/qa.json`,JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
if(!report.pass)process.exitCode=1;
