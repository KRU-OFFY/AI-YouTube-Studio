-- TOFFY AI YouTube Studio — ปิด M2: sanitize audit metadata ที่ระดับ DB
--
-- เดิม sanitize อยู่แค่ฝั่ง TS (lib/audit/sanitize.ts) → ถ้าเรียก log_audit RPC ตรง
-- (ข้าม TS wrapper) จะเก็บ secret/PII ดิบได้ (ละเมิด NFR-009 เชิง defense-in-depth)
-- แก้: sanitize ที่ DB ใน log_audit เอง — deny-list ชุดเดียวกับฝั่ง TS + ปิด gap L1
-- (signing_key, session_id ที่ heuristic TS พลาด) + mask email
--
-- ขอบเขต: strip top-level + recurse เข้า nested object (ครอบมากกว่า TS ปัจจุบัน)
-- ไม่แตะ 0006 (immutable แล้ว) · signature log_audit คงเดิมเป๊ะเพื่อรักษา grant/revoke

set search_path = public;

-- pure transform: strip key อ่อนไหว (case-insensitive) + mask email ; recurse nested object
create or replace function public.sanitize_audit_metadata(input jsonb)
returns jsonb
language plpgsql
immutable
security definer
set search_path = ''
as $$
declare
  result jsonb := '{}'::jsonb;
  k text;
  v jsonb;
  lk text;
  is_sensitive boolean;
  s text;
  email_txt text;
  masked text;
  -- ให้สอดคล้องกับ lib/audit/sanitize.ts + ปิด gap ที่ audit L1 ชี้ (signing_key, session_id)
  substr_sensitive text[] := array[
    'password','passwd','token','secret','apikey','api_key','authorization',
    'cookie','jwt','credential','private_key','access_key','signing_key','session_id'
  ];
  exact_sensitive text[] := array['key','pass','auth','pwd'];
begin
  if input is null or jsonb_typeof(input) <> 'object' then
    return '{}'::jsonb;   -- ไม่ throw กับ input ว่าง/ผิด shape
  end if;

  for k, v in select key, value from jsonb_each(input)
  loop
    lk := lower(k);

    is_sensitive := (lk = any(exact_sensitive));
    if not is_sensitive then
      foreach s in array substr_sensitive loop
        if position(s in lk) > 0 then
          is_sensitive := true;
          exit;
        end if;
      end loop;
    end if;

    if is_sensitive then
      continue;  -- ตัดทิ้ง
    elsif jsonb_typeof(v) = 'object' then
      -- recurse เข้า nested object
      result := result || jsonb_build_object(k, public.sanitize_audit_metadata(v));
    elsif position('email' in lk) > 0 and jsonb_typeof(v) = 'string' then
      -- mask email: เก็บตัวแรก + โดเมน (a***@b.com)
      email_txt := v #>> '{}';
      if position('@' in email_txt) > 1 then
        masked := left(email_txt, 1) || '***@' || split_part(email_txt, '@', 2);
      else
        masked := '***';
      end if;
      result := result || jsonb_build_object(k, to_jsonb(masked));
    else
      result := result || jsonb_build_object(k, v);
    end if;
  end loop;

  return result;
end $$;

-- แก้ log_audit ให้ sanitize ที่ DB ก่อน insert (signature เดิมเป๊ะ → grant/revoke จาก 0005 คงอยู่)
create or replace function public.log_audit(
  p_action text,
  p_entity_type text default null,
  p_entity_id uuid default null,
  p_workspace_id uuid default null,
  p_result audit_result default 'success',
  p_metadata jsonb default '{}'::jsonb
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.audit_logs
    (workspace_id, actor_user_id, action, entity_type, entity_id, result, metadata)
  values
    (p_workspace_id, auth.uid(), p_action, p_entity_type, p_entity_id, p_result,
     public.sanitize_audit_metadata(coalesce(p_metadata, '{}'::jsonb)));
end $$;
