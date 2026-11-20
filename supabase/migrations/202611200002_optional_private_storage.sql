-- Future optional scan uploads. v1 uses metadata only; no upload UI enabled.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('private-documents','private-documents',false,5242880,array['application/pdf','image/jpeg','image/png']) on conflict(id) do nothing;
create policy own_documents_read on storage.objects for select to authenticated using(bucket_id='private-documents' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy own_documents_insert on storage.objects for insert to authenticated with check(bucket_id='private-documents' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy own_documents_update on storage.objects for update to authenticated using(bucket_id='private-documents' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='private-documents' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy own_documents_delete on storage.objects for delete to authenticated using(bucket_id='private-documents' and (storage.foldername(name))[1]=(select auth.uid())::text);
