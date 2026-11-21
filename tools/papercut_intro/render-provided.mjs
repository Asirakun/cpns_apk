import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {selectComposition,renderMedia,renderStill} from '@remotion/renderer';
import {openVerifiedGpuBrowser} from './gpu-browser.mjs';
const root='../../cpns-intro';
fs.mkdirSync('src/provided',{recursive:true});fs.mkdirSync('public/sfx',{recursive:true});fs.mkdirSync('../../docs/design/v1.2.2/intro',{recursive:true});
for(const name of ['book-open.png','book-closed.png','road-rot.png','flag.png'])fs.copyFileSync(`${root}/public/${name}`,`public/${name}`);
for(const name of fs.readdirSync(`${root}/public/sfx`))fs.copyFileSync(`${root}/public/sfx/${name}`,`public/sfx/${name}`);
let src=fs.readFileSync(`${root}/src/CpnsIntro.tsx`,'utf8');
src=src.replace("import {loadFont} from '@remotion/google-fonts/PlusJakartaSans';",'');
const fontStart=src.indexOf('const {fontFamily}');const fontEnd=src.indexOf("const GOLD",fontStart);
src=src.slice(0,fontStart)+"const fontFamily='PlusJakarta';\n"+src.slice(fontEnd);
src=src.replace("'radial-gradient(circle at 50% 42%, #0e2f57 0%, #0a2240 55%, #071a33 100%)'","'#08223B'");
const rings=src.indexOf('          {/* lingkaran');const inset=src.indexOf('              inset: 0,',rings);const bookDiv=src.lastIndexOf('          <div',inset);
src=src.slice(0,rings)+src.slice(bookDiv);
src=src.replace('{SFX.map',"<style>{`@font-face{font-family:PlusJakarta;src:url('${staticFile('PlusJakartaSans.ttf')}')}`}</style>\n      {SFX.map");
fs.writeFileSync('src/provided/CpnsIntro.tsx',src);
let book=fs.readFileSync(`${root}/src/BookImages.tsx`,'utf8');const glow=book.indexOf('      {/* cahaya');const images=book.indexOf('      {/* buku terbuka',glow);book=book.slice(0,glow)+book.slice(images);fs.writeFileSync('src/provided/BookImages.tsx',book);
fs.writeFileSync('src/provided/index.tsx',"import React from 'react';import{registerRoot,Composition}from'remotion';import{CpnsIntro}from'./CpnsIntro';registerRoot(()=> <Composition id='ProvidedIntro' component={CpnsIntro} width={1440} height={3200} fps={30} durationInFrames={200}/>);\n");
const r=spawnSync(process.execPath,[path.resolve('node_modules/@remotion/cli/remotion-cli.js'),'bundle','src/provided/index.tsx','--out-dir=out/provided/bundle'],{stdio:'inherit'});if(r.status!==0)throw Error('Bundle failed');
const {browser,report}=await openVerifiedGpuBrowser();
try{
 const common={serveUrl:path.resolve('out/provided/bundle'),puppeteerInstance:browser,logLevel:'error',inputProps:{},concurrency:2};
 const composition=await selectComposition({...common,id:'ProvidedIntro'});
 await renderStill({...common,composition,frame:180,imageFormat:'png',output:'../../docs/design/v1.2.2/intro/provided-still.png'});
 await renderMedia({...common,composition,codec:'h264',hardwareAcceleration:'required',videoBitrate:'24M',audioCodec:'aac',outputLocation:'../../docs/design/v1.2.2/intro/provided-intro-with-sfx.mp4'});
 fs.writeFileSync('../../docs/design/v1.2.2/intro/gpu-render.json',JSON.stringify({...report,frames:200,fps:30,audio:'Original seven supplied SFX stems',source:'cpns-intro',background:'Original gradient/rings/glow removed; preview navy #08223B; application uses native PaperBackdrop',nvencRequired:true},null,2));
}finally{await browser.close({silent:true});}
