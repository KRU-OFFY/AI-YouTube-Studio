-- RLS + Gate 0 harness — Task 1.3
-- ต้องรันตามลำดับ: _supabase_shim.sql → 0001 → 0002 → 0003 → 0004 → ไฟล์นี้
-- พิสูจน์: (ก) Gate 0 draft สร้าง episode ไม่ได้ / approved ได้
--          (ข) user B เข้าถึง channel/episodes ของ workspace A ไม่ได้ที่ระดับ DB
--          (ค) channel_id ของ episodes เป็น NOT NULL (ปิดจบหลัง 0004)

\set ON_ERROR_STOP on

insert into auth.users (id) values
  ('11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222')
on conflict do nothing;

-- ── (ค) channel_id ต้องเป็น NOT NULL ─────────────────────────────────
do $$
declare n int;
begin
  select count(*) into n from information_schema.columns
   where table_schema='public' and table_name in ('pillars','characters','episodes')
     and column_name='channel_id' and is_nullable='YES';
  if n <> 0 then raise exception 'FAIL: ยังมี channel_id ที่ nullable อยู่ % คอลัมน์', n; end if;
end $$;

-- ═══ User A: workspace + channel (draft) ═══
set role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111"}',false);

select (public.create_workspace('WS-A','Asia/Bangkok','THB')).id as ws_a \gset
select set_config('test.ws_a', :'ws_a', false);

insert into public.channels (workspace_id, name, slug)
  values (:'ws_a', 'Channel A', 'chan-a');
select id from public.channels where workspace_id = :'ws_a' and slug='chan-a' \gset
select set_config('test.ch_a', :'id', false);

-- ── (ก) Gate 0: channel ยัง draft → สร้าง episode ไม่ได้ ──────────────
do $$
declare ch uuid := current_setting('test.ch_a')::uuid; blocked boolean := false;
begin
  begin
    insert into public.episodes (channel_id, title) values (ch, 'ตอนต้องห้าม (draft)');
  exception when raise_exception then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: Gate 0 ไม่กัน — สร้าง episode ใน channel draft ได้'; end if;
end $$;

-- [M1] เปลี่ยน status ผ่าน UPDATE ตรง → ต้องถูกกัน (บังคับผ่าน approve_channel)
do $$
declare ch uuid := current_setting('test.ch_a')::uuid; blocked boolean := false;
begin
  begin
    update public.channels set status = 'approved' where id = ch;
  exception when raise_exception then blocked := true;
  end;
  if not blocked then
    raise exception 'FAIL: เปลี่ยน channel.status ผ่าน UPDATE ตรงได้ (ต้องผ่าน approve_channel เท่านั้น)';
  end if;
end $$;

-- อนุมัติ channel ผ่าน RPC → สร้าง episode ได้
select public.approve_channel(current_setting('test.ch_a')::uuid);
do $$
declare ch uuid := current_setting('test.ch_a')::uuid; n int;
begin
  insert into public.episodes (channel_id, title) values (ch, 'ตอนแรกหลังอนุมัติ');
  select count(*) into n from public.episodes where channel_id = ch;
  if n <> 1 then raise exception 'FAIL: หลังอนุมัติควรสร้าง episode ได้ (เห็น % แถว)', n; end if;
end $$;

-- ═══ User B: ต้องเข้าถึงของ A ไม่ได้ ═══
select set_config('request.jwt.claims','{"sub":"22222222-2222-2222-2222-222222222222"}',false);
do $$
declare ch uuid := current_setting('test.ch_a')::uuid; n int; denied boolean := false;
begin
  -- B เห็น channel ของ A ไหม
  select count(*) into n from public.channels where id = ch;
  if n <> 0 then raise exception 'FAIL: B เห็น channel ของ A (% แถว)', n; end if;

  -- B เห็น episodes ของ channel A ไหม
  select count(*) into n from public.episodes where channel_id = ch;
  if n <> 0 then raise exception 'FAIL: B เห็น episodes ของ A (% แถว)', n; end if;

  -- B แทรก episode เข้า channel A → ต้องถูกปฏิเสธ (RLS write)
  begin
    insert into public.episodes (channel_id, title) values (ch, 'hacked-by-B');
    -- ถ้าไม่โดน RLS จะโดน Gate 0 (approved แล้ว) — ดังนั้นต้องมาจาก RLS
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'FAIL: B แทรก episode เข้า channel ของ A ได้'; end if;

  -- B อนุมัติ channel ของ A → ต้อง raise (ไม่ใช่ owner)
  denied := false;
  begin
    perform public.approve_channel(ch);
  exception when raise_exception then denied := true;
  end;
  if not denied then raise exception 'FAIL: B อนุมัติ channel ของ A ได้'; end if;
end $$;

-- ═══ A ยังเห็น/จัดการของตัวเองได้ ═══
select set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111"}',false);
do $$
declare ch uuid := current_setting('test.ch_a')::uuid; n int;
begin
  select count(*) into n from public.channels where id = ch and status = 'approved';
  if n <> 1 then raise exception 'FAIL: A ควรเห็น channel ตัวเอง (approved)'; end if;
  select count(*) into n from public.episodes where channel_id = ch;
  if n <> 1 then raise exception 'FAIL: A ควรเห็น episode ตัวเอง 1 แถว (เห็น %)', n; end if;
end $$;

reset role;
\echo '========================================='
\echo 'CHANNELS RLS + GATE 0 HARNESS PASSED'
\echo '========================================='
