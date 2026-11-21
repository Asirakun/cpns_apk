import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import sharp from 'sharp';
import {openVerifiedGpuBrowser} from './gpu-browser.mjs';
import {selectComposition,renderFrames,renderMedia,renderStill} from '@remotion/renderer';

const cli=path.resolve('node_modules/@remotion/cli/remotion-cli.js');
function run(args){const r=spawnSync(process.execPath,args,{stdio:'inherit'});if(r.error||r.status!==0)throw r.error||new Error('Tool failed '+r.status);}
const destination='../../docs/design/v1.2.1/intro';
fs.mkdirSync(destination,{recursive:true});
fs.mkdirSync('out/hd',{recursive:true});
// Keep the original generated artwork's pixels, instead of enlarging the
// 512px launcher/header derivative. Only transparent outside margins are trimmed.
await sharp('../../docs/design/v1.2.0/logo-source.png').trim().png().toFile('public/intro-logo.png');
fs.copyFileSync('../../assets/fonts/PlusJakartaSans.ttf','public/PlusJakartaSans.ttf');
run([cli,'bundle','src/index.tsx','--out-dir=out/hd/bundle']);
const {browser,report}=await openVerifiedGpuBrowser();
const started=Date.now();
try {
 const common={serveUrl:path.resolve('out/hd/bundle'),puppeteerInstance:browser,logLevel:'error',concurrency:2};
 const composition=await selectComposition({...common,id:'Intro',inputProps:{mcDebug:false}});
 await renderStill({...common,composition,inputProps:{mcDebug:false},frame:65,imageFormat:'png',output:`${destination}/intro-still.png`});
 const probeStart=Date.now();
 await renderMedia({...common,composition,inputProps:{mcDebug:false},frameRange:[40,47],codec:'h264',videoBitrate:'24M',
   hardwareAcceleration:'required',pixelFormat:'yuv420p',outputLocation:'out/hd/nvenc-probe.mp4',muted:true});
 report.nvencProbe={pass:true,frames:8,elapsedMs:Date.now()-probeStart,hardwareAcceleration:'required'};
 fs.writeFileSync(`${destination}/gpu-render.json`,JSON.stringify(report,null,2));
 if(process.argv.includes('--preview')){console.log('QHD+ still and RTX/NVENC probe ready');}
 else {
  const mark=await selectComposition({...common,id:'IntroMark',inputProps:{}});
  await renderFrames({...common,composition:mark,inputProps:{},imageFormat:'png',outputDir:'out/hd/mark-frames',
    onStart:()=>console.log('Rendering 96 transparent HD mark frames on verified RTX browser'),
    onFrameUpdate:(count)=>{if(count%24===0)console.log(`Mark frames ${count}/96`);}});
  run(['export-native.mjs']);
  if(process.argv.includes('--webp'))run(['encode-webp.mjs']);
  await renderMedia({...common,composition,inputProps:{mcDebug:false},codec:'h264',videoBitrate:'24M',
    hardwareAcceleration:'required',pixelFormat:'yuv420p',outputLocation:`${destination}/papercut-intro-qhd.mp4`,muted:true,
    onProgress:()=>{}});
  const debug={mcDebug:true};
  const debugComposition=await selectComposition({...common,id:'Intro',inputProps:debug});
  await renderFrames({...common,composition:debugComposition,inputProps:debug,scale:.25,imageFormat:'png',outputDir:'out/hd/debug-frames',
    onStart:()=>console.log('Rendering debug frame checks'),onFrameUpdate:()=>{}});
  report.completed=true;report.elapsedMs=Date.now()-started;report.previewVideo={width:1440,height:3200,frames:96,encoder:'NVENC (required, no CPU fallback)'};
  fs.writeFileSync(`${destination}/gpu-render.json`,JSON.stringify(report,null,2));
  console.log('HD mark and QHD+ NVENC master completed');
 }
} finally {await browser.close({silent:true});}
