-- RLS harness — ทดสอบว่า multi-tenancy ของ workspaces บังคับที่ระดับ DB จริง
-- รันด้วย psql (ON_ERROR_STOP=1). ถ้ามี assertion พลาด จะ RAISE EXCEPTION → exit != 0
--
-- ต้องรันตามลำดับ: _supabase_shim.sql → 0001 → 0002 → ไฟล์นี้
-- (shim สร้าง schema auth / auth.uid() / role authenticated ที่ Supabase มีให้อยู่แล้ว)

\set ON_ERROR_STOP on

-- ── ผู้ใช้ทดสอบ 2 คน ─────────────────────────────────────────────────
insert into auth.users (id) values
  ('11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222')
on conflict do nothing;

-- ═══════════════════════════════════════════════════════════════════
-- User A สร้าง workspace (ผ่าน RPC) แล้วเก็บ id ไว้ใน GUC test.ws_a
-- ═══════════════════════════════════════════════════════════════════
set role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111"}', false);

select (public.create_workspace('WS-A', 'Asia/Bangkok', 'THB')).id as ws_a \gset
select set_config('test.ws_a', :'ws_a', false);

-- A ต้องเห็น workspace ของตัวเอง + เป็น owner
do $$
declare n int;
begin
  select count(*) into n from public.workspaces
    where id = current_setting('test.ws_a')::uuid;
  if n <> 1 then raise exception 'FAIL: A ควรเห็น workspace ตัวเอง 1 แถว แต่เห็น %', n; end if;

  select count(*) into n from public.workspace_members
    where workspace_id = current_setting('test.ws_a')::uuid
      and user_id = auth.uid() and role = 'owner';
  if n <> 1 then raise exception 'FAIL: A ควรเป็น owner ของ workspace ตัวเอง'; end if;
end $$;

-- ═══════════════════════════════════════════════════════════════════
-- User B ต้องเข้าถึงข้อมูลของ A ไม่ได้ แม้ยิง query ตรง (ไม่ผ่าน UI)
-- ═══════════════════════════════════════════════════════════════════
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222"}', false);

do $$
declare
  ws_a uuid := current_setting('test.ws_a')::uuid;
  n int;
  affected int;
  insert_denied boolean := false;
begin
  -- (1) B SELECT workspace ของ A → ต้องได้ 0 แถว
  select count(*) into n from public.workspaces where id = ws_a;
  if n <> 0 then raise exception 'FAIL: B เห็น workspace ของ A (% แถว)', n; end if;

  -- (2) B UPDATE workspace ของ A → ต้องแก้ได้ 0 แถว
  update public.workspaces set name = 'hacked-by-B' where id = ws_a;
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'FAIL: B แก้ workspace ของ A ได้ % แถว', affected; end if;

  -- (3) B INSERT ตัวเองเป็น member ของ A → ต้องถูก RLS ปฏิเสธ
  begin
    insert into public.workspace_members (workspace_id, user_id, role)
    values (ws_a, auth.uid(), 'owner');
  exception when insufficient_privilege then
    insert_denied := true;
  end;
  if not insert_denied then
    raise exception 'FAIL: B แทรกตัวเองเข้า workspace ของ A ได้ (RLS ไม่กัน)';
  end if;

  -- (4) B SELECT รายชื่อสมาชิกของ A → ต้องได้ 0 แถว
  select count(*) into n from public.workspace_members where workspace_id = ws_a;
  if n <> 0 then raise exception 'FAIL: B เห็นสมาชิกของ workspace A (% แถว)', n; end if;
end $$;

-- ═══════════════════════════════════════════════════════════════════
-- ยืนยัน policy ไม่ over-block: A ยังเห็น/จัดการ workspace ตัวเองได้
-- ═══════════════════════════════════════════════════════════════════
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111"}', false);

do $$
declare ws_a uuid := current_setting('test.ws_a')::uuid; affected int; n int;
begin
  update public.workspaces set name = 'WS-A (renamed by owner)' where id = ws_a;
  get diagnostics affected = row_count;
  if affected <> 1 then raise exception 'FAIL: owner ควรแก้ workspace ตัวเองได้ แต่แก้ได้ % แถว', affected; end if;

  select count(*) into n from public.workspaces where name = 'WS-A (renamed by owner)';
  if n <> 1 then raise exception 'FAIL: การ rename ของ owner ไม่ถูกบันทึก'; end if;
end $$;

reset role;
\echo '==================================='
\echo 'RLS HARNESS PASSED — ครบทุก assertion'
\echo '==================================='
