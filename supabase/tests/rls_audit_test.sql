-- RLS + append-only harness — Task 1.4 (audit_logs)
-- ต้องรันตามลำดับ: _supabase_shim.sql → 0001 → 0002 → 0003 → 0004 → 0005 → ไฟล์นี้
-- พิสูจน์: (ก) append-only (update/delete → raise)  (ข) client insert ตรงไม่ได้ (ต้องผ่าน RPC)
--          (ค) actor ปลอมไม่ได้ (= auth.uid())  (ง) B เห็น audit ของ A ไม่ได้
--          (จ) anon SELECT = 0 แถว + anon เขียน (log_audit) ไม่ได้

\set ON_ERROR_STOP on

insert into auth.users (id) values
  ('11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222')
on conflict do nothing;

-- ═══ A: สร้าง workspace + เขียน audit ผ่าน RPC ═══
set role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111"}',false);
select (public.create_workspace('WS-A','Asia/Bangkok','THB')).id as ws_a \gset
select set_config('test.ws_a', :'ws_a', false);

select public.log_audit('workspace.create','workspace',null,:'ws_a','success','{"name":"WS-A"}');

-- (ค) actor = auth.uid() (ปลอมไม่ได้ — log_audit ไม่รับ actor param)
do $$
declare ws uuid := current_setting('test.ws_a')::uuid; a uuid;
begin
  select actor_user_id into a from public.audit_logs where workspace_id=ws limit 1;
  if a is distinct from '11111111-1111-1111-1111-111111111111'::uuid then
    raise exception 'FAIL: actor ไม่ตรง auth.uid() (=%);', a;
  end if;
end $$;

-- (ข) client insert ตรง → ต้องถูกปฏิเสธ (ไม่มี INSERT policy)
do $$
declare ws uuid := current_setting('test.ws_a')::uuid; denied boolean := false;
begin
  begin
    insert into public.audit_logs(workspace_id, action) values (ws, 'forged.direct');
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: client insert ตรงเข้า audit_logs ได้ (ควรผ่าน RPC เท่านั้น)'; end if;
end $$;

-- ═══ B: เห็น audit ของ A ไม่ได้ ═══
select set_config('request.jwt.claims','{"sub":"22222222-2222-2222-2222-222222222222"}',false);
do $$
declare ws uuid := current_setting('test.ws_a')::uuid; n int;
begin
  select count(*) into n from public.audit_logs where workspace_id = ws;
  if n <> 0 then raise exception 'FAIL: B เห็น audit ของ workspace A (% แถว)', n; end if;
end $$;

-- ═══ (จ) anon: SELECT = 0 แถว + เขียนไม่ได้ ═══
reset role;
set role anon;
select set_config('request.jwt.claims','{}', false);
do $$
declare n int; denied boolean := false;
begin
  select count(*) into n from public.audit_logs;   -- RLS: anon ไม่มี policy → 0 แถว
  if n <> 0 then raise exception 'FAIL: anon เห็น audit_logs % แถว (ควร 0)', n; end if;

  begin
    perform public.log_audit('anon.attempt');       -- anon ไม่ได้ grant execute
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: anon เรียก log_audit ได้ (ควรถูกปฏิเสธ)'; end if;
end $$;

-- ═══ (ก) append-only: update/delete → raise (ทดสอบด้วยสิทธิ์ superuser) ═══
reset role;
do $$
declare blocked boolean := false;
begin
  begin
    update public.audit_logs set action = 'tampered';
  exception when others then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: UPDATE audit_logs ได้ (ควร append-only)'; end if;

  blocked := false;
  begin
    delete from public.audit_logs;
  exception when others then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: DELETE audit_logs ได้ (ควร append-only)'; end if;
end $$;

\echo '========================================='
\echo 'AUDIT RLS + APPEND-ONLY HARNESS PASSED'
\echo '========================================='
