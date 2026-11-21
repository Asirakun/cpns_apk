import fs from 'node:fs';import crypto from 'node:crypto';import{spawnSync}from'node:child_process';import{scenes}from'./src/story.js';
const ff='tools/ffmpeg.exe',sr=48000;
const source=JSON.parse(fs.readFileSync('audio/elevenlabs-v2/index.json','utf8'));
const complete=JSON.parse(fs.readFileSync('audio/elevenlabs-v2/complete.json','utf8'));
if(source.length!==scenes.length||complete.provider!=='ElevenLabs'||!source.every((s,i)=>s.scene===i&&s.status==='completed'&&s.provider==='ElevenLabs'))throw Error('Complete ElevenLabs narration is required.');
// Preserve every sample so the provider timestamps stay aligned.
const rawClips=source.map(s=>decode(s.audio));
fs.mkdirSync('out/remotion-v2',{recursive:true});fs.mkdirSync('remotion-video/public/audio',{recursive:true});
const slots=[];let offset=0;for(let i=0;i<scenes.length;i++){const duration=Math.max(scenes[i].end-scenes[i].start,rawClips[i].length/sr+1.2);slots.push({scene:i,slotStart:offset,slotEnd:offset+duration,baseStart:scenes[i].start,baseEnd:scenes[i].end});offset+=duration;}
const totalDuration=Math.ceil(offset*60)/60,N=Math.round(totalDuration*sr),L=new Float32Array(N),R=new Float32Array(N),voice=new Float32Array(N);let seed=9031;
const realTime=t=>{const slot=slots.find(s=>t>=s.baseStart&&t<s.baseEnd)||slots.at(-1);return slot.slotStart+(t-slot.baseStart)/(slot.baseEnd-slot.baseStart)*(slot.slotEnd-slot.slotStart)};
const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)|0;return(seed>>>0)/4294967296};
function exec(args){const p=spawnSync(ff,args,{maxBuffer:100*1024*1024});if(p.status!==0)throw Error(p.stderr.toString());return p.stdout}
function decode(file,filters=''){const b=exec(['-v','error','-i',file,...(filters?['-af',filters]:[]),'-f','f32le','-ac','1','-ar',String(sr),'pipe:1']);return new Float32Array(b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength))}
function wav(file,a,b){const n=a.length,out=Buffer.alloc(44+n*4);out.write('RIFF');out.writeUInt32LE(out.length-8,4);out.write('WAVEfmt ',8);out.writeUInt32LE(16,16);out.writeUInt16LE(1,20);out.writeUInt16LE(2,22);out.writeUInt32LE(sr,24);out.writeUInt32LE(sr*4,28);out.writeUInt16LE(4,32);out.writeUInt16LE(16,34);out.write('data',36);out.writeUInt32LE(n*4,40);for(let i=0;i<n;i++){out.writeInt16LE(Math.round(Math.max(-1,Math.min(1,a[i]))*32767),44+i*4);out.writeInt16LE(Math.round(Math.max(-1,Math.min(1,b[i]))*32767),46+i*4)}fs.writeFileSync(file,out)}
const timing=[];
for(let i=0;i<scenes.length;i++){const a=rawClips[i],q=slots[i];let rms=Math.sqrt(a.reduce((v,x)=>v+x*x,0)/a.length),gain=Math.min(2,.12/rms);const start=q.slotStart+.45,off=Math.round(start*sr);for(let j=0;j<a.length&&off+j<N;j++)voice[off+j]+=Math.tanh(a[j]*gain*1.12)/1.12;const captions=source[i].captions.map(c=>({...c,start:c.start+start,end:c.end+start}));if(captions.some(c=>!Number.isFinite(c.start)||!Number.isFinite(c.end)||c.end<c.start||c.end>start+a.length/sr+.05))throw Error('Invalid caption timestamps in scene '+i);timing.push({...q,start,duration:a.length/sr,rate:1,captions});}
fs.writeFileSync('audio/elevenlabs-v2/timing.json',JSON.stringify(timing,null,2));wav('audio/elevenlabs-v2/narration.wav',voice,voice);
const freq=m=>440*2**((m-69)/12);const beat=2/3,bar=beat*4;
function add(t,d,fn,amp=.1,pan=0){const start=Math.round(t*sr),n=Math.round(d*sr),lg=Math.sqrt((1-pan)/2),rg=Math.sqrt((1+pan)/2);for(let j=0;j<n&&start+j<N;j++){if(start+j<0)continue;const v=fn(j/sr,j)*amp;L[start+j]+=v*lg;R[start+j]+=v*rg}}
function pluck(t,n,d,amp,pan=0){let hz=freq(n),size=Math.round(sr/hz),buf=new Float32Array(size);for(let k=0;k<size;k++)buf[k]=(random()*2-1)*.7;let at=0;add(t,d,(s,j)=>{const v=buf[at];buf[at]=(buf[at]+buf[(at+1)%size])*.497;at=(at+1)%size;return v*Math.min(1,s*130)*Math.exp(-s*.7)},amp,pan)}
function piano(t,n,d,amp,pan){const hz=freq(n);add(t,d,s=>Math.min(1,s*100)*Math.exp(-s*2)*(Math.sin(s*hz*Math.PI*2)+.24*Math.sin(s*hz*Math.PI*4)+.08*Math.sin(s*hz*Math.PI*6)),amp,pan)}
const chords=[[50,57,62,66],[47,54,59,62],[43,50,55,59],[45,52,57,61]];
for(let b=0;b<Math.ceil(totalDuration/bar);b++){const t=b*bar,notes=chords[Math.floor(b/2)%4];let intensity=t<8?.38:t<40?.75:t<74?.88:t<108?.72:.5;
for(let j=0;j<8;j++)pluck(t+j*beat/2,notes[(j+[0,2,1,3][b%4])%4]+12,1.7,.12*intensity,(j%2?1:-1)*.35);
piano(t,notes[0]-12,2.5,.075*intensity,-.2);for(let j=0;j<3;j++)piano(t+beat*(j+.5),notes[j]+24,1.3,.02*intensity,.4);
if(t>=18&&t<108){add(t,.13,s=>Math.sin(2*Math.PI*(78*s-120*s*s))*Math.exp(-s*35),.035);add(t+beat*2,.12,s=>(random()*2-1)*Math.exp(-s*45),.009);}
}
// A short original closing cadence; all music is synthesized locally.
for(let j=0;j<4;j++)piano(totalDuration-4+j*.22,[62,66,69,74][j],3.5,.06,j*.2-.3);
const cues=[];function paper(t,d=.25,amp=.06){t=realTime(t);let prev=0,low=0;add(t,d,s=>{const n=random()*2-1;low=.91*low+.09*n;let hp=n-low;prev=.55*prev+.45*hp;return prev*Math.sin(Math.PI*s/d)**2},amp,(random()-.5)*.6);cues.push({time:t,type:'paper',duration:d})}
function tap(t){t=realTime(t);add(t,.09,s=>Math.sin(2*Math.PI*180*s)*Math.exp(-s*55)+(random()*2-1)*Math.exp(-s*90)*.3,.065);cues.push({time:t,type:'card-tap'})}
for(const t of [8,16.5,38.5,72.5,111.4])paper(t,t===8?.9:1.3,.105);
for(const t of [18.5,18.72,18.94,24.5,29,29.38,29.76,40.5,43,51,55,63,63.24,63.48,74.8,75.2,75.6,76,78,86.3,89,99,109.4,115.3]){paper(t,.16,.045);tap(t+.08)}
let room=0;for(let i=0;i<N;i++){room=room*.985+(random()*2-1)*.00005;const t=i/sr;let duck=1;for(const q of timing){if(t>q.start-.25&&t<q.start+q.duration+.4){const fadeIn=Math.min(1,(t-q.start+.25)/.25),fadeOut=Math.min(1,(q.start+q.duration+.4-t)/.4);duck=Math.min(duck,1-.65*Math.min(fadeIn,fadeOut))}}const fade=Math.min(1,t/1.5,(totalDuration-t)/1.4);L[i]=(L[i]*duck+room)*fade+voice[i];R[i]=(R[i]*duck+room)*fade+voice[i];}
wav('audio/elevenlabs-v2/mix-raw.wav',L,R);exec(['-v','info','-y','-i','audio/elevenlabs-v2/mix-raw.wav','-af','loudnorm=I=-14:TP=-1.2:LRA=9:print_format=json','-ar',String(sr),'-c:a','pcm_s16le','audio/elevenlabs-v2/final.wav']);fs.writeFileSync('audio/elevenlabs-v2/cues.json',JSON.stringify(cues,null,2));
function stamp(t){const ms=Math.round(t*1000),h=Math.floor(ms/3600000),m=Math.floor(ms/60000)%60,s=Math.floor(ms/1000)%60;return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')},${String(ms%1000).padStart(3,'0')}`}
let srt='',counter=0;for(const q of timing)for(const c of q.captions)srt+=`${++counter}\n${stamp(c.start)} --> ${stamp(c.end)}\n${c.text}\n\n`;
fs.writeFileSync('out/remotion-v2/CPNS_JOURNEY_REMOTION_ID.srt',srt);console.log('Mixed original music, paper foley and ElevenLabs Indonesian narration.');console.log(JSON.stringify({voice:complete.voice.name,scenes:timing.length,captions:counter,duration:totalDuration,speedAdjustment:1}));

fs.copyFileSync('audio/elevenlabs-v2/final.wav','remotion-video/public/audio/elevenlabs-final.wav');
fs.writeFileSync('remotion-video/src/elevenlabs-timing.json',JSON.stringify(timing,null,2));
fs.writeFileSync('remotion-video/src/timeline.ts',`import timing from './elevenlabs-timing.json';
import {monotone} from './engine/lib';
export const FPS=60;
export const DURATION=${totalDuration};
export const NARRATION_SOURCE='audio/elevenlabs-final.wav';
export const audioTiming=timing;
const clock=monotone([...timing.map(t=>[t.slotStart,t.baseStart]),[${totalDuration},120]]);
export const baseTime=(seconds:number)=>clock(Math.max(0,Math.min(${totalDuration},seconds)));
`);
fs.writeFileSync('remotion-video/public/audio/narration-ready.json',JSON.stringify({provider:'ElevenLabs',voice:complete.voice.name,voiceId:complete.voice.voice_id,model:complete.model,language:'id',audioSource:'audio/elevenlabs-final.wav',sha256:crypto.createHash('sha256').update(fs.readFileSync('audio/elevenlabs-v2/final.wav')).digest('hex'),scenes:timing.length,naturalSpeech:true,speedAdjustment:1,duration:totalDuration},null,2));
