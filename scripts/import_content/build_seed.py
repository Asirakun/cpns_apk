"""Generate SQL for the project owner. No secrets or backend credentials required."""
import json,hashlib
from pathlib import Path
p=Path(__file__).resolve().parents[2]
data=json.loads((p/'assets/content/content.json').read_text())
def sql(v):
 if v is None:return 'null'
 if isinstance(v,(dict,list)):v=json.dumps(v,ensure_ascii=False)
 return "'"+str(v).replace("'","''")+"'"
source='b345bb6d-9a90-47c1-af0d-4274a86e2024'
lines=['begin;',f"insert into official_sources(id,publisher,url,title,cycle_year,status,publication_status) values('{source}','KemenPANRB / BKN','https://www.bkn.go.id/wp-content/uploads/2024/08/2024kepmenpanrb321-Nilai-Ambang-Batas.pdf','KepmenPANRB 321/2024 - referensi historis',2024,'historical','published') on conflict(id) do nothing;"]
for i,title in enumerate(['Target & persiapan','Pengumuman formasi','Akun SSCASN','Pendaftaran','Administrasi & sanggah','SKD','Hasil SKD','SKB','Hasil akhir & sanggah','DRH & pemberkasan','Pengangkatan & penempatan','Arsip / coba lagi']):lines.append(f"insert into journey_stages values('S{i:02d}',{i},{sql(title)},'published') on conflict(stage_code) do nothing;")
topics={}
for obj in [*data['questions'],*data['lessons']]:topics[(obj['domain'],obj['topic'])]=obj['domain']+'-'+hashlib.sha256(obj['topic'].encode()).hexdigest()[:12]
for (domain,title),key in topics.items():lines.append(f"insert into topics values({sql(key)},{sql(domain)},{sql(title)},'published') on conflict(id) do nothing;")
for q in data['questions']:
 vals=[q['id'],q['domain'],topics[(q['domain'],q['topic'])],q['text'],'weighted' if q['domain']=='TKP' else 'single',q['level'],q['explanation'],q['review_status'],q['reviewer'],q['license']]
 lines.append('insert into questions(id,domain,topic_id,text_md,type,level,explanation,review_status,reviewer,license,version,publication_status) values('+','.join(map(sql,vals))+",1,'published') on conflict(id) do nothing;")
 for o in q['options']:lines.append(f"insert into question_options values({sql(o['id'])},{sql(q['id'])},{sql(o['text'])},{o['score']},{str(o['score']==5).lower()}) on conflict(question_id,id) do nothing;")
for l in data['lessons']:
 vals=[l['id'],l['domain'],topics[(l['domain'],l['topic'])],l['title'],'\n\n'.join(l['body'])]
 lines.append('insert into lessons(id,domain,topic_id,title,body_md,duration,version,reviewer,review_status,publication_status) values('+','.join(map(sql,vals))+f",{l['minutes']},1,'content-validator-v1','automated_validation_only','published') on conflict(id) do nothing;")
lines.append(f"insert into exam_blueprints values('historical-2024-v1',2024,'{{\"TWK\":30,\"TIU\":35,\"TKP\":45}}',6000,'{{\"single_correct\":5,\"single_wrong\":0,\"blank\":0,\"TKP\":\"option_weight\"}}','{{\"TWK\":65,\"TIU\":80,\"TKP\":166}}','{source}','historical',1,'reference-from-PRD','published') on conflict(id) do nothing;")
for pack in data['packs']:
 lines.append(f"insert into exam_packs values({sql(pack['id'])},{sql(pack['name'])},1,'historical-2024-v1','published') on conflict(id) do nothing;")
 for i,qid in enumerate(pack['question_ids']):lines.append(f"insert into pack_questions values({sql(pack['id'])},{sql(qid)},{i}) on conflict(pack_id,question_id) do nothing;")
m=json.loads((p/'assets/content/manifest.json').read_text())
lines.append(f"insert into content_releases(version,content_hash,size_bytes,published_at,minimum_app_version,notes,reviewer,publication_status) values('1.0.0',{sql(m['sha256'])},{m['bytes']},now(),'1.0.0','Original template-based practice; human subject-matter review pending.','automated-validator','published') on conflict(version) do nothing;")
lines.append('commit;');(p/'supabase/seed.sql').write_text('\n'.join(lines)+'\n')
print('Seed:',len(data['questions']),'original practice questions. No invented 2026 formations/deadlines.')
