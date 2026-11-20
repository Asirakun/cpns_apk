-- Supabase PostgreSQL. Never place a service-role/secret key in the application.
begin;
create table public.profiles(user_id uuid primary key references auth.users(id) on delete cascade,alias text not null,target_city text not null,education_used text not null,d3_status text not null,graduation_estimate date,settings_json jsonb not null default '{}',updated_at timestamptz not null default now());
create table public.official_sources(id uuid primary key default gen_random_uuid(),publisher text not null,url text not null check(url ~ '^https://'),title text not null,cycle_year integer,published_at timestamptz,verified_at timestamptz,status text not null check(status in ('draft','reference','historical','verified')),checksum text,publication_status text not null default 'draft',check(status<>'verified' or verified_at is not null));
create table public.recruitment_cycles(id uuid primary key default gen_random_uuid(),year integer not null,agency text not null,official_status text not null default 'pending',source_id uuid references public.official_sources(id),verified_at timestamptz,publication_status text not null default 'draft');
create table public.formations(id uuid primary key default gen_random_uuid(),cycle_id uuid not null references public.recruitment_cycles(id),role text not null,unit text,eligible_educations text[] not null,location_formasi text,test_city text,placement_policy text not null,source_id uuid not null references public.official_sources(id),publication_status text not null default 'draft');
create table public.journey_stages(stage_code text primary key,display_order integer unique not null,title text not null,publication_status text not null default 'published');
create table public.requirement_rules(id uuid primary key default gen_random_uuid(),cycle_id uuid references public.recruitment_cycles(id),stage_code text not null references public.journey_stages(stage_code),doc_kind text not null,required boolean,ext text[],max_size integer,valid_period integer,source_id uuid references public.official_sources(id),publication_status text not null default 'draft');
create table public.topics(id text primary key,domain text not null check(domain in ('TWK','TIU','TKP','SKB')),title text not null,publication_status text not null default 'draft');
create table public.lessons(id text primary key,domain text not null,topic_id text references public.topics(id),title text not null,body_md text not null,duration integer,asset_refs jsonb not null default '[]',version integer not null,reviewer text,review_status text not null default 'pending',published_at timestamptz,publication_status text not null default 'draft');
create table public.questions(id text primary key,domain text not null check(domain in ('TWK','TIU','TKP','SKB')),topic_id text references public.topics(id),text_md text not null,type text not null,level text,explanation text not null check(length(explanation)>0),review_status text not null,reviewer text,license text not null,version integer not null,asset_refs jsonb not null default '[]',publication_status text not null default 'draft');
create table public.question_options(id text not null,question_id text not null references public.questions(id) on delete cascade,content text not null,option_score integer not null check(option_score between 0 and 5),is_correct boolean not null default false,primary key(question_id,id));
create table public.exam_blueprints(id text primary key,cycle_year integer not null,distribution_json jsonb not null,duration_sec integer not null check(duration_sec>0),scoring_rules jsonb not null,passing_grades jsonb,source_id uuid not null references public.official_sources(id),status text not null check(status in ('historical','draft','verified')),version integer not null,reviewer text not null,publication_status text not null default 'draft');
create table public.exam_packs(id text primary key,title text not null,version integer not null,blueprint_id text not null references public.exam_blueprints(id),publication_status text not null default 'draft');
create table public.pack_questions(pack_id text not null references public.exam_packs(id) on delete cascade,question_id text not null references public.questions(id),ordering integer not null,primary key(pack_id,question_id),unique(pack_id,ordering));
create table public.content_releases(id uuid primary key default gen_random_uuid(),version text unique not null,content_hash text not null,size_bytes integer,download_url text,published_at timestamptz,minimum_app_version text,notes text,reviewer text not null,publication_status text not null default 'draft');
-- Snapshot = atomic synchronization unit; structured tables support Studio inspection.
create table public.user_snapshots(user_id uuid primary key references auth.users(id) on delete cascade,payload jsonb not null,version bigint not null default 1,updated_at timestamptz not null default now());
create table public.sync_operations(user_id uuid not null references auth.users(id) on delete cascade,operation_id uuid not null,result_version bigint not null,created_at timestamptz not null default now(),primary key(user_id,operation_id));
create table public.user_formations(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,formation_id uuid references public.formations(id),selected_at timestamptz,risk_acknowledged boolean not null default false,selection_notes text);
create table public.user_stage_status(user_id uuid not null references auth.users(id) on delete cascade,cycle_id text not null,stage_code text not null references public.journey_stages(stage_code),status text not null check(status in ('BELUM_DIMULAI','AKTIF','MENUNGGU_HASIL','SELESAI','TIDAK_LOLOS')),recorded_at timestamptz not null default now(),evidence_url text,primary key(user_id,cycle_id,stage_code));
create table public.user_documents(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,cycle_id text,doc_kind text,rule_id uuid references public.requirement_rules(id),status text not null,expires_at timestamptz,notes text,storage_path text,updated_at timestamptz not null default now(),unique(user_id,cycle_id,doc_kind));
create table public.exam_attempts(id uuid primary key,user_id uuid not null references auth.users(id) on delete cascade,blueprint_id text,pack_id text,seed bigint,started_at timestamptz not null,deadline_at timestamptz not null,submitted_at timestamptz,status text not null check(status in ('active','submitted')),score_json jsonb not null,snapshot jsonb not null,server_version bigint not null default 1,updated_at timestamptz not null default now());
create table public.exam_answers(user_id uuid not null references auth.users(id) on delete cascade,attempt_id uuid not null references public.exam_attempts(id) on delete cascade,question_id text not null,question_version integer not null,option_id text,answered_at timestamptz,elapsed_ms integer,primary key(attempt_id,question_id));
create table public.lesson_progress(user_id uuid not null references auth.users(id) on delete cascade,lesson_id text not null,position integer not null default 0,completed_at timestamptz,primary key(user_id,lesson_id));
create table public.reviews(user_id uuid not null references auth.users(id) on delete cascade,question_id text not null,next_review_at timestamptz,wrong_count integer not null default 0,primary key(user_id,question_id));
create table public.study_plans(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,date date,minutes_target integer,checked boolean not null default false);
create table public.reminders(id uuid primary key,user_id uuid not null references auth.users(id) on delete cascade,reminder_type text,scheduled_at timestamptz,enabled boolean not null default false,source_id uuid references public.official_sources(id));
create table public.user_budget_items(id uuid primary key,user_id uuid not null references auth.users(id) on delete cascade,expense_type text not null,estimate_idr bigint not null check(estimate_idr>=0),actual_idr bigint not null check(actual_idr>=0),recorded_at timestamptz not null default now());
create table public.audit_logs(id uuid primary key default gen_random_uuid(),actor_uid uuid,action text not null,entity text,entity_id text,created_at timestamptz not null default now());
create index attempts_user_date on public.exam_attempts(user_id,started_at desc);
create index documents_user on public.user_documents(user_id,cycle_id);
create index formation_filters on public.formations(cycle_id,location_formasi);
create index published_questions on public.questions(domain,publication_status);
create index sync_user_date on public.sync_operations(user_id,created_at);
do $$ declare t text; begin
 foreach t in array array['official_sources','recruitment_cycles','formations','journey_stages','requirement_rules','topics','lessons','questions','exam_blueprints','exam_packs','content_releases'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from anon,authenticated',t);
  execute format('grant select on public.%I to anon,authenticated',t);
  execute format('create policy published_read on public.%I for select to anon,authenticated using(publication_status=''published'')',t);
 end loop;
 foreach t in array array['profiles','user_snapshots','sync_operations','user_formations','user_stage_status','user_documents','exam_attempts','exam_answers','lesson_progress','reviews','study_plans','reminders','user_budget_items'] loop
  execute format('alter table public.%I enable row level security',t);
  -- Writes are only exposed via an atomic, authenticated RPC.
  execute format('revoke all on public.%I from anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
  execute format('create policy owner_read on public.%I for select to authenticated using((select auth.uid())=user_id)',t);
 end loop;
end $$;
alter table public.question_options enable row level security;
alter table public.pack_questions enable row level security;
alter table public.audit_logs enable row level security;
revoke all on public.question_options,public.pack_questions,public.audit_logs from anon,authenticated;
grant select on public.question_options,public.pack_questions to anon,authenticated;
create policy published_options on public.question_options for select to anon,authenticated using(exists(select 1 from public.questions q where q.id=question_id and q.publication_status='published'));
create policy published_pack_questions on public.pack_questions for select to anon,authenticated using(exists(select 1 from public.exam_packs p where p.id=pack_id and p.publication_status='published') and exists(select 1 from public.questions q where q.id=question_id and q.publication_status='published'));
create function public.guard_immutable_attempt() returns trigger language plpgsql set search_path=public,pg_temp as $$ begin
 if old.submitted_at is not null and new.snapshot is distinct from old.snapshot then raise exception 'Submitted attempt is immutable';end if;return new;
end $$;
create trigger immutable_submitted_attempt before update on public.exam_attempts for each row execute function public.guard_immutable_attempt();
create function public.score_snapshot(p_attempt jsonb) returns jsonb language plpgsql immutable set search_path=public,pg_temp as $$
declare q jsonb;opt jsonb;answer text;points integer;domain text;scores jsonb:='{"TWK":0,"TIU":0,"TKP":0}';seen text[]:='{}';
begin
 if jsonb_typeof(p_attempt->'questions')<>'array' or jsonb_array_length(p_attempt->'questions')=0 or jsonb_array_length(p_attempt->'questions')>200 then raise exception 'Invalid question snapshot';end if;
 for q in select value from jsonb_array_elements(p_attempt->'questions') loop
  domain:=q->>'domain';if domain not in ('TWK','TIU','TKP') or q->>'id'=any(seen) then raise exception 'Invalid domain or duplicate question';end if;
  seen:=array_append(seen,q->>'id');points:=0;answer:=p_attempt->'answers'->>(q->>'id');
  if jsonb_array_length(q->'options')<>5 then raise exception 'Invalid options';end if;
  if (select count(distinct o->>'id') from jsonb_array_elements(q->'options') o)<>5 then raise exception 'Duplicate option';end if;
  for opt in select value from jsonb_array_elements(q->'options') loop
   if (opt->>'score')::int<0 or (opt->>'score')::int>5 then raise exception 'Invalid score';end if;
   if opt->>'id'=answer then points:=(opt->>'score')::int;end if;
  end loop;
  if answer is not null and not exists(select 1 from jsonb_array_elements(q->'options') o where o->>'id'=answer) then raise exception 'Invalid answer';end if;
  scores:=jsonb_set(scores,array[domain],to_jsonb((scores->>domain)::int+points));
 end loop;return scores;
end $$;
create function public.sync_user_state(p_operation_id uuid,p_expected_version bigint,p_payload jsonb) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid();current_version bigint;prior bigint;v bigint;attempt jsonb;old_attempt public.exam_attempts;score jsonb;q jsonb;c jsonb;pair record;doc jsonb;
begin
 if uid is null then raise exception 'Authentication required';end if;
 if jsonb_typeof(p_payload)<>'object' or (p_payload->>'schema_version')::int<>1 or octet_length(p_payload::text)>12000000 then raise exception 'Invalid or oversized payload';end if;
 perform pg_advisory_xact_lock(hashtextextended(uid::text,0));
 select result_version into prior from public.sync_operations where user_id=uid and operation_id=p_operation_id;
 if found then return jsonb_build_object('version',prior,'duplicate',true,'conflict',false);end if;
 select version into current_version from public.user_snapshots where user_id=uid for update;
 current_version:=coalesce(current_version,0);
 if p_expected_version<>-1 and p_expected_version<>current_version then return jsonb_build_object('conflict',true,'version',current_version);end if;
 v:=current_version+1;
 for attempt in select value from jsonb_array_elements(p_payload->'attempts') loop
  old_attempt:=null;select * into old_attempt from public.exam_attempts where id=(attempt->>'id')::uuid;
  if found and old_attempt.user_id<>uid then raise exception 'Attempt identity collision';end if;
  if old_attempt.submitted_at is not null and old_attempt.snapshot is distinct from attempt then raise exception 'Submitted attempt is immutable';end if;
  if (attempt->>'deadline_at')::timestamptz<(attempt->>'started_at')::timestamptz then raise exception 'Invalid deadline';end if;
  score:=public.score_snapshot(attempt);
  if attempt->>'submitted_at' is not null and attempt->'scores' is distinct from score then raise exception 'Score mismatch';end if;
  insert into public.exam_attempts(id,user_id,blueprint_id,pack_id,seed,started_at,deadline_at,submitted_at,status,score_json,snapshot,server_version)
  values((attempt->>'id')::uuid,uid,attempt->'blueprint'->>'id',attempt->>'pack_id',(attempt->>'seed')::bigint,(attempt->>'started_at')::timestamptz,(attempt->>'deadline_at')::timestamptz,(attempt->>'submitted_at')::timestamptz,case when attempt->>'submitted_at' is null then 'active' else 'submitted' end,score,attempt,v)
  on conflict(id) do update set submitted_at=excluded.submitted_at,status=excluded.status,score_json=excluded.score_json,snapshot=excluded.snapshot,server_version=v,updated_at=now();
  if old_attempt.submitted_at is null then
   for q in select value from jsonb_array_elements(attempt->'questions') loop
    insert into public.exam_answers(user_id,attempt_id,question_id,question_version,option_id,answered_at)
    values(uid,(attempt->>'id')::uuid,q->>'id',(q->>'version')::int,attempt->'answers'->>(q->>'id'),(attempt->>'answered_at')::timestamptz)
    on conflict(attempt_id,question_id) do update set option_id=excluded.option_id,answered_at=excluded.answered_at;
   end loop;
  end if;
 end loop;
 if exists(select 1 from public.exam_attempts a where a.user_id=uid and not exists(select 1 from jsonb_array_elements(p_payload->'attempts') x where x->>'id'=a.id::text)) then raise exception 'Snapshot omits synced attempts; use a complete backup';end if;
 insert into public.profiles(user_id,alias,target_city,education_used,d3_status,graduation_estimate,settings_json)
 values(uid,p_payload->>'alias',p_payload->>'target_city',p_payload->>'education',p_payload->>'d3_status',(p_payload->>'graduation')::date,jsonb_build_object('minutes',p_payload->'minutes','plan_days',p_payload->'plan_days','theme',p_payload->'theme'))
 on conflict(user_id) do update set alias=excluded.alias,target_city=excluded.target_city,education_used=excluded.education_used,d3_status=excluded.d3_status,settings_json=excluded.settings_json,updated_at=now();
 for c in select value from jsonb_array_elements(p_payload->'cycles') loop
  for pair in select * from jsonb_each_text(c->'stages') loop
   insert into public.user_stage_status(user_id,cycle_id,stage_code,status,evidence_url) values(uid,c->>'id',pair.key,pair.value,c->'evidence'->pair.key->>'source')
   on conflict(user_id,cycle_id,stage_code) do update set status=excluded.status,evidence_url=excluded.evidence_url,recorded_at=now();
  end loop;
  for pair in select * from jsonb_each(c->'documents') loop
   doc:=pair.value;
   insert into public.user_documents(user_id,cycle_id,doc_kind,status,expires_at,notes) values(uid,c->>'id',pair.key,doc->>'status',(doc->>'expires_at')::timestamptz,doc->>'note')
   on conflict(user_id,cycle_id,doc_kind) do update set status=excluded.status,expires_at=excluded.expires_at,notes=excluded.notes,updated_at=now();
  end loop;
 end loop;
 for pair in select * from jsonb_each_text(p_payload->'lesson_positions') loop
  insert into public.lesson_progress(user_id,lesson_id,position,completed_at) values(uid,pair.key,pair.value::int,case when p_payload->'completed' ? pair.key then now() else null end)
  on conflict(user_id,lesson_id) do update set position=greatest(lesson_progress.position,excluded.position),completed_at=coalesce(lesson_progress.completed_at,excluded.completed_at);
 end loop;
 insert into public.user_snapshots(user_id,payload,version) values(uid,p_payload,v) on conflict(user_id) do update set payload=excluded.payload,version=v,updated_at=now();
 insert into public.sync_operations values(uid,p_operation_id,v,now());
 return jsonb_build_object('conflict',false,'version',v);
end $$;
create function public.delete_my_account() returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid();begin
 if uid is null then raise exception 'Authentication required';end if;
 delete from auth.users where id=uid; -- cascading deletion: metadata-only v1 stores no uploaded objects.
end $$;
revoke all on function public.sync_user_state(uuid,bigint,jsonb),public.delete_my_account(),public.score_snapshot(jsonb),public.guard_immutable_attempt() from public,anon,authenticated;
grant execute on function public.sync_user_state(uuid,bigint,jsonb),public.delete_my_account() to authenticated;
commit;
