-- Supabase shim สำหรับรัน migration/RLS harness บน Postgres เปล่า (เครื่องทดสอบ)
-- จำลองสิ่งที่ Supabase มีให้อยู่แล้ว: schema auth, auth.users, auth.uid(), role authenticated
-- ต้องรัน "ก่อน" migration 0002 (เพราะ 0002 มี FK → auth.users และ grant → authenticated)
-- ไฟล์นี้ใช้เฉพาะตอนทดสอบ — ไม่ใช่ migration จริง

create schema if not exists auth;
create table if not exists auth.users (id uuid primary key);

-- auth.uid() อ่าน sub จาก GUC request.jwt.claims (เลียนแบบ Supabase)
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  -- ทน claims ว่าง/ไม่ตั้งค่า (คืน null) เหมือนพฤติกรรม Supabase จริง
  select nullif(
    nullif(current_setting('request.jwt.claims', true), '')::json ->> 'sub', ''
  )::uuid;
$$;

do $$ begin
  create role authenticated nologin;
exception when duplicate_object then null; end $$;
do $$ begin
  create role anon nologin;
exception when duplicate_object then null; end $$;

grant usage on schema auth to authenticated, anon;
grant execute on function auth.uid() to authenticated, anon;
grant usage on schema public to anon;
