-- PRD v2.1: add-only extension of the existing snapshot, no new database/table.
-- Old clients remain schema_version=1 and cannot erase newer analytics fields.
-- Existing RPC scoring/immutability/outbox/version checks are unchanged.
begin;
create or replace function public.merge_analytics_records(a jsonb,b jsonb) returns jsonb
language plpgsql immutable set search_path=public,pg_temp as $$
declare field text; item jsonb; existing jsonb; records jsonb; result jsonb;
begin
 if a is null or a='null'::jsonb then a:='{}'::jsonb; end if;
 if b is null or b='null'::jsonb then b:='{}'::jsonb; end if;
 if a='{}'::jsonb and b='{}'::jsonb then return null; end if;
 foreach item in array array[a,b] loop
  if item<>'{}'::jsonb and (jsonb_typeof(item) is distinct from 'object' or item->'version' is distinct from '1'::jsonb or
      jsonb_typeof(item->'sessions') is distinct from 'array' or jsonb_typeof(item->'goals') is distinct from 'array' or
      jsonb_typeof(item->'tracking_started_at') is distinct from 'string') then raise exception 'Invalid analytics structure'; end if;
 end loop;
 result:=a||b;
 foreach field in array array['sessions','goals'] loop
  records:='{}'::jsonb;
  for item in select value from jsonb_array_elements(coalesce(a->field,'[]'::jsonb)||coalesce(b->field,'[]'::jsonb)) loop
   if jsonb_typeof(item) is distinct from 'object' or coalesce(item->>'id','')='' then raise exception 'Invalid analytics record'; end if;
   perform (item->>'id')::uuid;
   existing:=records->(item->>'id');
   if existing is not null and existing is distinct from item then raise exception 'Immutable analytics identity collision'; end if;
   if field='sessions' then
    if jsonb_typeof(item->'active_seconds') is distinct from 'number' or
       coalesce(item->>'kind','') not in ('lesson','practice','cat','review') or
       (item->>'category' is not null and item->>'category' not in ('TWK','TIU','TKP')) or
       item->>'source' is distinct from 'foreground-v1' or
       item->>'started_at' is null or item->>'ended_at' is null or item->>'local_day' is null then raise exception 'Invalid study session'; end if;
    if (item->>'active_seconds')::numeric<=0 or (item->>'active_seconds')::numeric>120 or
       (item->>'active_seconds')::numeric>extract(epoch from ((item->>'ended_at')::timestamptz-(item->>'started_at')::timestamptz))+.002 or
       (item->>'local_day')::date<>((item->>'started_at')::timestamptz at time zone 'Asia/Jakarta')::date then raise exception 'Invalid study duration or WIB day'; end if;
   else
    if jsonb_typeof(item->'minutes') is distinct from 'number' or (item->>'minutes')::int not between 0 and 180 or
       item->>'effective_day' is null or item->>'created_at' is null then raise exception 'Invalid study target'; end if;
    perform (item->>'effective_day')::date;
    perform (item->>'created_at')::timestamptz;
   end if;
   records:=jsonb_set(records,array[item->>'id'],item);
  end loop;
  result:=jsonb_set(result,array[field],coalesce((select jsonb_agg(value order by key) from jsonb_each(records)),'[]'::jsonb));
 end loop;
 result:=jsonb_set(result,'{tracking_started_at}',to_jsonb(least((a->>'tracking_started_at')::timestamptz,(b->>'tracking_started_at')::timestamptz)));
 return result;
end $$;

create or replace function public.preserve_snapshot_analytics() returns trigger
language plpgsql set search_path=public,pg_temp as $$
declare merged jsonb;
begin
 merged:=public.merge_analytics_records(case when TG_OP='UPDATE' then OLD.payload->'analytics' else null end,NEW.payload->'analytics');
 if merged is not null then NEW.payload:=jsonb_set(NEW.payload,'{analytics}',merged); end if;
 if octet_length(NEW.payload::text)>12000000 then raise exception 'Merged snapshot exceeds payload limit'; end if;
 return NEW;
end $$;

-- A new trigger only; does not rewrite pre-existing snapshots during migration.
create trigger preserve_snapshot_analytics before insert or update of payload
 on public.user_snapshots for each row execute function public.preserve_snapshot_analytics();
revoke all on function public.merge_analytics_records(jsonb,jsonb) from public,anon,authenticated;
revoke all on function public.preserve_snapshot_analytics() from public,anon,authenticated;
create or replace function public.analytics_capabilities() returns jsonb
language plpgsql stable set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 return '{"version":1}'::jsonb;
end $$;
revoke all on function public.analytics_capabilities() from public,anon,authenticated;
grant execute on function public.analytics_capabilities() to authenticated;
commit;
