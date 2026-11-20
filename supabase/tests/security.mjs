// Run: npm install --no-save @electric-sql/pglite && node supabase/tests/security.mjs
// Real embedded PostgreSQL with Supabase auth/storage schemas represented by fixtures.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
const root=new URL('../../',import.meta.url);
const read=p=>fs.readFileSync(new URL(p,root),'utf8');
const db=new PGlite();
await db.exec(`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key,email text);create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;grant usage on schema auth,public to anon,authenticated;grant execute on function auth.uid() to anon,authenticated;create schema storage;create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text references storage.buckets(id),name text);alter table storage.objects enable row level security;grant usage on schema storage to authenticated;grant select,insert,update,delete on storage.objects to authenticated;create function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name,'/') $$;`);
await db.exec(read('supabase/migrations/202611200001_initial.sql'));
await db.exec(read('supabase/migrations/202611200002_optional_private_storage.sql'));
await db.exec(read('supabase/seed.sql'));
const A='11111111-1111-4111-8111-111111111111',B='22222222-2222-4222-8222-222222222222';
await db.query('insert into auth.users values($1,$2),($3,$4)',[A,'a@example.test',B,'b@example.test']);
const asUser=async uid=>{await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[uid]);await db.exec('set role authenticated');};
const content=JSON.parse(read('assets/content/content.json'));
const pack=content.packs[0];
const questions=pack.question_ids.map(id=>content.questions.find(q=>q.id===id));
const attempt={id:randomUUID(),title:'RLS test CAT',pack_id:pack.id,seed:42,started_at:'2026-11-20T10:00:00Z',deadline_at:'2026-11-20T11:40:00Z',submitted_at:'2026-11-20T11:00:00Z',questions,answers:Object.fromEntries(questions.map(q=>[q.id,q.options.find(o=>o.score===5).id])),flagged:[],index:109,blueprint:{id:'historical-2024-v1',status:'historical'},scores:{TWK:150,TIU:175,TKP:225}};
const payload={schema_version:1,alias:'Tester A',target_city:'Medan',education:'SMA',d3_status:'Sedang kuliah',graduation:'2027-04-01',minutes:45,plan_days:30,theme:'system',attempts:[attempt],cycles:[{id:'cycle-2026',stages:{S00:'AKTIF'},evidence:{},documents:{ijazah:{status:'Siap',note:'Sudah diperiksa'}}}],lesson_positions:{'lesson-01':4},completed:['lesson-01']};
const sync=async(op,version,data)=> (await db.query('select public.sync_user_state($1,$2,$3::jsonb) as result',[op,version,JSON.stringify(data)])).rows[0].result;
let passed=0;
function ok(name){passed++;console.log('PASS',name);}
await asUser(A);const op=randomUUID();assert.equal((await sync(op,0,payload)).version,1);ok('authenticated sync and deterministic 550 scoring');
assert.equal((await sync(op,0,payload)).duplicate,true);assert.equal((await db.query('select count(*)::int as n from exam_attempts')).rows[0].n,1);ok('idempotent retry does not duplicate attempts');
assert.equal((await sync(randomUUID(),0,payload)).conflict,true);ok('stale device produces an explicit conflict');
await asUser(B);assert.equal((await db.query('select count(*)::int as n from user_snapshots')).rows[0].n,0);assert.equal((await db.query('select count(*)::int as n from exam_answers')).rows[0].n,0);assert.equal((await db.query('select count(*)::int as n from profiles')).rows[0].n,0);ok('account B cannot read account A');
await assert.rejects(()=>sync(randomUUID(),0,payload),/collision/);ok('account B cannot reuse account A attempt ID');
await assert.rejects(()=>db.exec("update questions set text_md='tamper'"),/permission denied/);await assert.rejects(()=>db.exec("update profiles set alias='tamper'"),/permission denied/);ok('master and direct user writes are denied');
await asUser(A);const modified=structuredClone(payload);modified.attempts[0].answers[questions[0].id]='Z';await assert.rejects(()=>sync(randomUUID(),1,modified),/immutable/);ok('submitted answer snapshot is immutable');
const invalid=structuredClone(payload);invalid.attempts[0].id=randomUUID();invalid.attempts[0].scores.TWK=999;await assert.rejects(()=>sync(randomUUID(),1,invalid),/Score mismatch/);ok('server rejects inconsistent scores');
await db.query('insert into storage.objects(bucket_id,name) values($1,$2)',['private-documents',`${A}/test.pdf`]);await asUser(B);assert.equal((await db.query('select count(*)::int as n from storage.objects')).rows[0].n,0);await assert.rejects(()=>db.query('insert into storage.objects(bucket_id,name) values($1,$2)',['private-documents',`${A}/bad.pdf`]),/row-level security/);ok('private bucket isolates read and write paths');
await asUser(A);await db.exec('delete from storage.objects');await db.exec('select public.delete_my_account()');await db.exec('reset role');assert.equal((await db.query('select count(*)::int as n from auth.users where id=$1',[A])).rows[0].n,0);for(const t of ['profiles','user_snapshots','exam_attempts','exam_answers','sync_operations','user_documents','lesson_progress'])assert.equal((await db.query(`select count(*)::int as n from ${t} where user_id=$1`,[A])).rows[0].n,0);ok('account deletion cascades through owned data');
const tables=await db.query("select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r'");assert.ok(tables.rows.every(t=>t.relrowsecurity));ok(`RLS enabled on all ${tables.rows.length} public tables`);
await db.exec('set role anon');assert.equal((await db.query('select count(*)::int as n from questions')).rows[0].n,450);await assert.rejects(()=>db.query('select public.sync_user_state($1,0,$2)',[randomUUID(),JSON.stringify(payload)]),/permission denied/);ok('anonymous user reads only published content and cannot sync');
await db.close();console.log(`${passed} database/security checks passed`);
