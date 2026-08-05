-- Asset provenance + Rights RLS harness — FR-009 / ADR-003 (migration 0010)
-- ต้องรันตามลำดับ: _supabase_shim.sql → 0001..0010 → ไฟล์นี้
-- พิสูจน์: (ก) create_asset_with_rights (owner) สร้าง asset+rights คู่กันได้
--          (ข) rights_records UNIQUE ต่อ asset (insert ซ้ำ blocked)
--          (ค) workspace อื่น (B) select/insert/update asset+rights ไม่ได้ (RLS)
--          (ง) viewer (channel_read แต่ไม่ write) สร้าง/แก้ asset ไม่ได้

\set ON_ERROR_STOP on

insert into auth.users (id) values
  ('a1111111-1111-1111-1111-111111111111'),
  ('b2222222-2222-2222-2222-222222222222'),
  ('c3333333-3333-3333-3333-333333333333')
on conflict do nothing;

-- ═══ A (owner): workspace + channel (approved) + asset ผ่าน RPC ═══
set role authenticated;
select set_config('request.jwt.claims','{"sub":"a1111111-1111-1111-1111-111111111111"}',false);

select (public.create_workspace('WS-ASSET','Asia/Bangkok','THB')).id as ws_a \gset
select set_config('test.ws_a', :'ws_a', false);
insert into public.channels (workspace_id, name, slug) values (:'ws_a','Chan Asset','chan-asset');
select id from public.channels where workspace_id = :'ws_a' and slug='chan-asset' \gset
select set_config('test.ch_a', :'id', false);
select public.approve_channel(:'id');

-- (ก) สร้าง asset + rights คู่กัน
select (public.create_asset_with_rights(
  current_setting('test.ch_a')::uuid, 'image', 'anchor', 'น้องปุยยิ้ม',
  null, 'assets/pui-smile.png', 'firefly',
  'Adobe Firefly', 'paid', 'Firefly Image 3', 'a cute puff smiling', 'https://ex/1', 'CC-internal', now()
)).id as aid \gset
select set_config('test.asset', :'aid', false);

do $$
declare n_a int; n_r int;
begin
  select count(*) into n_a from public.assets where id = current_setting('test.asset')::uuid;
  select count(*) into n_r from public.rights_records where asset_id = current_setting('test.asset')::uuid;
  if n_a <> 1 then raise exception 'FAIL: asset ไม่ถูกสร้าง'; end if;
  if n_r <> 1 then raise exception 'FAIL: rights record ไม่ถูกสร้างคู่ asset'; end if;
end $$;

-- (ข) UNIQUE: insert rights ซ้ำ asset_id เดียว → blocked
do $$
declare blocked boolean := false;
begin
  begin
    insert into public.rights_records (asset_id, tool_used, exported_at)
      values (current_setting('test.asset')::uuid, 'dup', now());
  exception when unique_violation then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: insert rights ซ้ำ asset_id ได้ (ต้อง 1:1)'; end if;
end $$;

-- ═══ B (คนละ workspace, non-member): เข้าถึงของ A ไม่ได้ ═══
select set_config('request.jwt.claims','{"sub":"b2222222-2222-2222-2222-222222222222"}',false);
do $$
declare ch uuid := current_setting('test.ch_a')::uuid;
        aid uuid := current_setting('test.asset')::uuid;
        n int; denied boolean := false;
begin
  -- (ค1) select asset/rights ของ A → 0
  select count(*) into n from public.assets where channel_id = ch;
  if n <> 0 then raise exception 'FAIL: B เห็น asset ของ A (% แถว)', n; end if;
  select count(*) into n from public.rights_records where asset_id = aid;
  if n <> 0 then raise exception 'FAIL: B เห็น rights ของ A (% แถว)', n; end if;

  -- (ค2) insert asset เข้า channel A → denied (RLS with check)
  begin
    insert into public.assets (channel_id, type, storage_path) values (ch, 'image', 'hack');
  exception when others then denied := true;
  end;
  if not denied then raise exception 'FAIL: B แทรก asset เข้า channel A ได้'; end if;

  -- (ค3) update asset ของ A → RLS กรอง (0 แถว)
  update public.assets set title = 'hacked-by-B' where id = aid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: B แก้ asset ของ A ได้ (% แถว)', n; end if;
end $$;

-- ═══ C (viewer ของ WS-A): อ่านได้ แต่เขียนไม่ได้ ═══
reset role;
insert into public.workspace_members (workspace_id, user_id, role)
  values (current_setting('test.ws_a')::uuid, 'c3333333-3333-3333-3333-333333333333', 'viewer')
on conflict do nothing;

set role authenticated;
select set_config('request.jwt.claims','{"sub":"c3333333-3333-3333-3333-333333333333"}',false);
do $$
declare ch uuid := current_setting('test.ch_a')::uuid;
        aid uuid := current_setting('test.asset')::uuid;
        n int; denied boolean := false;
begin
  -- (ง1) viewer อ่าน asset ได้ (channel_read)
  select count(*) into n from public.assets where id = aid;
  if n <> 1 then raise exception 'FAIL: viewer ควรอ่าน asset ได้ (เห็น %)', n; end if;

  -- (ง2) viewer สร้าง asset ผ่าน RPC → raise (has_channel_write=false)
  begin
    perform public.create_asset_with_rights(
      ch, 'image', 'scene', 'x', null, 'p', 't', 'tool', null, null, null, null, null, now());
  exception when raise_exception then denied := true;
  end;
  if not denied then raise exception 'FAIL: viewer สร้าง asset ได้'; end if;

  -- (ง3) viewer insert asset ตรง → denied (RLS)
  denied := false;
  begin
    insert into public.assets (channel_id, type, storage_path) values (ch, 'image', 'v');
  exception when others then denied := true;
  end;
  if not denied then raise exception 'FAIL: viewer แทรก asset ตรงได้'; end if;

  -- (ง4) viewer update asset → RLS กรอง (0 แถว)
  update public.assets set title = 'v-edit' where id = aid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: viewer แก้ asset ได้ (% แถว)', n; end if;
end $$;

reset role;
\echo '========================================='
\echo 'ASSET + RIGHTS RLS HARNESS PASSED'
\echo '========================================='
