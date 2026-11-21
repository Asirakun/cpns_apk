import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {scenes} from '../src/story.js';

export const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const folder=path.join(root,'audio/elevenlabs-v2');
const local={};
const envPath=path.join(root,'.env.local');
if(fs.existsSync(envPath))for(const line of fs.readFileSync(envPath,'utf8').replace(/^\uFEFF/,'').split(/\r?\n/)){
 const m=line.match(/^\s*(?:export\s+)?([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/);if(!m)continue;
 let value=m[2];if((value.startsWith('"')&&value.endsWith('"'))||(value.startsWith("'")&&value.endsWith("'")))value=value.slice(1,-1);local[m[1]]=value;
}
const config=name=>local[name]||process.env[name]||'';
const key=config('ELEVENLABS_API_KEY')||config('ELEVEN_API_KEY')||config('XI_API_KEY');
const model=config('ELEVENLABS_MODEL_ID')||'eleven_multilingual_v2';
const settings={stability:.48,similarity_boost:.75,style:.15,use_speaker_boost:true,speed:.97};
const save=(file,value)=>{fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,JSON.stringify(value,null,2));};
const safe=s=>String(s).split(key||'\u0000').join('[redacted]');

async function api(endpoint,{body,timeout=180000}={}){
 if(!key)throw Error('ELEVENLABS_API_KEY belum diisi di .env.local.');
 const response=await fetch('https://api.elevenlabs.io'+endpoint,{method:body?'POST':'GET',redirect:'error',headers:{'xi-api-key':key,'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{}),signal:AbortSignal.timeout(timeout)});
 if(!response.ok){let message;try{const detail=await response.json();message=detail.detail?.message||detail.detail?.status||detail.error?.message||'Request rejected';}catch{message=response.statusText}const e=new Error(safe(`ElevenLabs HTTP ${response.status}: ${message}`));e.httpStatus=response.status;throw e;}
 return {response,data:await response.json()};
}

function voiceScore(v){const labels=JSON.stringify(v.labels||{}).toLowerCase(),languages=v.verified_languages||[];return (languages.some(l=>l.language==='id')?200:0)+(/indones|bahasa/.test(labels+' '+(v.description||'').toLowerCase())?150:0)+(/female/.test(labels)?12:0)+(/narrat|story|warm|calm/.test(labels+' '+(v.description||'').toLowerCase())?10:0)+(v.category==='professional'?5:0);}
async function selectVoice(){
 const selected=config('ELEVENLABS_VOICE_ID');if(selected)return {voice_id:selected,name:'Configured account voice'};
 const voices=[];let page='';
 for(let i=0;i<5;i++){const {data}=await api('/v2/voices?page_size=100'+(page?'&next_page_token='+encodeURIComponent(page):''));voices.push(...(data.voices||[]));if(!data.has_more||!data.next_page_token)break;page=data.next_page_token;}
 if(!voices.length)throw Error('Tidak ada suara yang tersedia. Isi ELEVENLABS_VOICE_ID di .env.local.');
 const female=voices.filter(v=>String(v.labels?.gender||'').toLowerCase()==='female');
 if(!female.length)throw Error('Tidak ditemukan suara berlabel female. Pilih voice wanita dan isi ELEVENLABS_VOICE_ID.');
 const voice=female.toSorted((a,b)=>voiceScore(b)-voiceScore(a))[0];
 save(path.join(folder,'voices.json'),voices.map(v=>({voice_id:v.voice_id,name:v.name,category:v.category,labels:v.labels,verified_languages:v.verified_languages})));
 return {voice_id:voice.voice_id,name:voice.name,labels:voice.labels,verified_languages:voice.verified_languages};
}

function captionsOf(alignment,display){
 if(!alignment?.characters?.length)throw Error('ElevenLabs tidak mengembalikan timestamp karakter.');
 const chars=alignment.characters,spoken=chars.join(''),displayParts=display.match(/[^.!?]+[.!?]?/g)||[display];
 const parts=[...spoken.matchAll(/[^.!?]+[.!?]?/g)].filter(m=>m[0].trim());
 if(parts.length!==displayParts.length)throw Error('Batas kalimat timestamp tidak cocok. Audio disimpan; periksa alignment sebelum mengirim ulang permintaan.');
 return parts.map((part,i)=>{let a=part.index,b=part.index+part[0].length-1;while(a<b&&/\s/.test(spoken[a]))a++;while(b>a&&/\s/.test(spoken[b]))b--;return {start:alignment.character_start_times_seconds[a],end:alignment.character_end_times_seconds[b],text:displayParts[i].trim()};});
}

export async function main(mode='inspect'){
 if(mode==='check'){console.log(JSON.stringify({apiKeyAvailable:Boolean(key),voiceConfigured:Boolean(config('ELEVENLABS_VOICE_ID')),model,secretFile:envPath},null,2));return;}
 if(!key)throw Error('Isi ELEVENLABS_API_KEY di '+envPath+' terlebih dahulu.');
 fs.mkdirSync(folder,{recursive:true});const voice=await selectVoice();
 const texts=JSON.parse(fs.readFileSync(path.join(root,'audio/voice-texts.json'),'utf8'));
 let quota=null;try{const{data}=await api('/v1/user/subscription');quota={remaining:Math.max(0,data.character_limit-data.character_count)};}catch(e){if(e.httpStatus!==401&&e.httpStatus!==403)throw e;}
 const characters=texts.reduce((n,t)=>n+t.length,0);save(path.join(folder,'selection.json'),{provider:'ElevenLabs',voice,model,settings,characters,quota});
 console.log(JSON.stringify({voice:voice.name,voiceId:voice.voice_id,model,inputCharacters:characters,...(quota?{remainingCharacters:quota.remaining}:{})}));
 if(mode!=='generate')return;
 const index=[];
 for(let i=0;i<texts.length;i++){
  const text=texts[i],fingerprint=crypto.createHash('sha256').update(JSON.stringify({voice:voice.voice_id,model,text,settings})).digest('hex');
  const stem='voice-'+String(i).padStart(2,'0')+'-'+fingerprint.slice(0,12),file=path.join(folder,stem+'.mp3'),receipt=path.join(folder,stem+'.request.json'),alignmentFile=path.join(folder,stem+'.alignment.json');
  let meta=fs.existsSync(receipt)?JSON.parse(fs.readFileSync(receipt,'utf8')):null;
  if(meta?.status==='submitting'||meta?.status==='submission_unknown')throw Error(`Status permintaan adegan ${i} belum pasti. Periksa riwayat ElevenLabs sebelum membuat ulang.`);
  if(!(meta?.status==='completed'&&fs.existsSync(file)&&fs.existsSync(alignmentFile))){
   if(quota&&quota.remaining<text.length)throw Error('Kuota ElevenLabs tidak cukup untuk narasi berikutnya.');
   save(receipt,{scene:i,fingerprint,status:'submitting',startedAt:new Date().toISOString()});
   try{
    const{data,response}=await api(`/v1/text-to-speech/${encodeURIComponent(voice.voice_id)}/with-timestamps?output_format=mp3_44100_128`,{body:{text,model_id:model,voice_settings:settings,seed:2411+i,...(i?{previous_text:texts[i-1]}:{}),...(i<texts.length-1?{next_text:texts[i+1]}:{})}});
    if(!data.audio_base64)throw Error('ElevenLabs tidak mengembalikan audio.');
    fs.writeFileSync(file,Buffer.from(data.audio_base64,'base64'));save(alignmentFile,data.alignment||data.normalized_alignment);
    meta={scene:i,fingerprint,status:'completed',provider:'ElevenLabs',voice_id:voice.voice_id,model,request_id:response.headers.get('request-id'),audio:path.relative(root,file).replaceAll('\\','/')};save(receipt,meta);if(quota)quota.remaining-=text.length;
   }catch(e){save(receipt,{scene:i,fingerprint,status:e.httpStatus?'failed':'submission_unknown',error:safe(e.message)});throw e;}
  }
  const alignment=JSON.parse(fs.readFileSync(alignmentFile,'utf8')),captions=captionsOf(alignment,scenes[i].text);
  index.push({...meta,captions});save(path.join(folder,'index.json'),index);console.log(`ElevenLabs scene ${i+1}/${texts.length} ready`);
 }
 save(path.join(folder,'complete.json'),{provider:'ElevenLabs',scenes:index.length,voice,model,characters});
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))main(process.argv[2]||'inspect').catch(e=>{console.error(safe(e.message));process.exitCode=1;});
