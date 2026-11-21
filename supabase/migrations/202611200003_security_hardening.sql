-- Harden RPC input validation without changing existing user snapshots.
-- Apply after the initial and optional storage migrations.
begin;
revoke create on schema public from public, anon, authenticated;
grant usage on schema public to anon, authenticated;
create or replace function public.score_snapshot(p_attempt jsonb) returns jsonb
language plpgsql immutable set search_path=public,pg_temp as $$
declare q jsonb; opt jsonb; answer text; points integer; domain text;
 scores jsonb:='{"TWK":0,"TIU":0,"TKP":0}'; seen text[]:='{}';
begin
 if p_attempt is null or jsonb_typeof(p_attempt) is distinct from 'object' or
    jsonb_typeof(p_attempt->'questions') is distinct from 'array' or
    jsonb_typeof(p_attempt->'answers') is distinct from 'object' then
  raise exception 'Invalid question snapshot';
 end if;
 if jsonb_array_length(p_attempt->'questions') not between 1 and 200 then
  raise exception 'Invalid question snapshot';
 end if;
 for q in select value from jsonb_array_elements(p_attempt->'questions') loop
  domain:=q->>'domain';
  if domain is null or domain not in ('TWK','TIU','TKP') or
     coalesce(q->>'id','')='' or q->>'id'=any(seen) or
     jsonb_typeof(q->'options') is distinct from 'array' then
   raise exception 'Invalid domain or question';
  end if;
  if jsonb_array_length(q->'options')<>5 or
     (select count(distinct o->>'id') from jsonb_array_elements(q->'options') o where coalesce(o->>'id','')<>'')<>5 then
   raise exception 'Invalid options';
  end if;
  seen:=array_append(seen,q->>'id'); points:=0; answer:=p_attempt->'answers'->>(q->>'id');
  for opt in select value from jsonb_array_elements(q->'options') loop
   if jsonb_typeof(opt->'score') is distinct from 'number' or
      (opt->>'score')::int not between 0 and 5 then raise exception 'Invalid score'; end if;
   if opt->>'id'=answer then points:=(opt->>'score')::int; end if;
  end loop;
  if domain='TKP' then
   if (select array_agg((o->>'score')::int order by (o->>'score')::int) from jsonb_array_elements(q->'options') o) <> array[1,2,3,4,5] then
    raise exception 'Invalid TKP rubric';
   end if;
  elsif (select count(*) from jsonb_array_elements(q->'options') o where (o->>'score')::int=5)<>1 or
        exists(select 1 from jsonb_array_elements(q->'options') o where (o->>'score')::int not in (0,5)) then
   raise exception 'Invalid single-answer rubric';
  end if;
  if answer is not null and not exists(select 1 from jsonb_array_elements(q->'options') o where o->>'id'=answer) then
   raise exception 'Invalid answer';
  end if;
  scores:=jsonb_set(scores,array[domain],to_jsonb((scores->>domain)::int+points));
 end loop;
 return scores;
end $$;
create or replace function public.sync_user_state(p_operation_id uuid,p_expected_version bigint,p_payload jsonb) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid();current_version bigint;prior bigint;v bigint;attempt jsonb;old_attempt public.exam_attempts;score jsonb;q jsonb;c jsonb;pair record;doc jsonb;
begin
 if uid is null then raise exception 'Authentication required';end if;
 if p_operation_id is null or p_expected_version is null or p_expected_version < -1 then
  raise exception 'Invalid sync arguments';
 end if;
 if p_payload is null or jsonb_typeof(p_payload) is distinct from 'object' or
    p_payload->'schema_version' is distinct from '1'::jsonb or
    octet_length(p_payload::text)>12000000 then
  raise exception 'Invalid or oversized payload';
 end if;
 if jsonb_typeof(p_payload->'attempts') is distinct from 'array' or
    jsonb_typeof(p_payload->'cycles') is distinct from 'array' or
    jsonb_typeof(p_payload->'lesson_positions') is distinct from 'object' or
    jsonb_typeof(p_payload->'completed') is distinct from 'array' then
  raise exception 'Invalid payload structure';
 end if;
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
revoke all on function public.score_snapshot(jsonb) from public,anon,authenticated;
revoke all on function public.sync_user_state(uuid,bigint,jsonb) from public,anon,authenticated;
grant execute on function public.sync_user_state(uuid,bigint,jsonb) to authenticated;
commit;
