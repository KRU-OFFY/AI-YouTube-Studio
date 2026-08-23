-- Episode state-transition harness — FR-010 (migration 0009)
-- ต้องรันตามลำดับ: _supabase_shim.sql → 0001..0009 → ไฟล์นี้
-- พิสูจน์: (ก) valid transition ผ่าน + status เปลี่ยน + audit เกิด
--          (ข) invalid transition → raise (ปฏิเสธฝั่ง server)
--          (ค) UPDATE episodes.status ตรง → blocked (trigger guard)
--          (ง) non-writer (ไม่ใช่ member) เรียก transition → raise (has_channel_write)
--          (จ) {any}→archived ผ่าน · publish จาก non-ready → blocked
--          (ฉ) DELETE episode: owner/editor → สำเร็จ (1 แถว) + cascade ลบ episode_characters
--          (ช) DELETE episode: viewer → 0 แถว (RLS บล็อก ไม่ error) + ตอนยังอยู่

\set ON_ERROR_STOP on

insert into auth.users (id) values
  ('11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222')
on conflict do nothing;

-- ═══ A (owner): workspace + channel (approved) + 2 episodes (draft) ═══
set role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111"}',false);

select (public.create_workspace('WS-EP','Asia/Bangkok','THB')).id as ws_ep \gset
insert into public.channels (workspace_id, name, slug) values (:'ws_ep','Chan EP','chan-ep');
select id from public.channels where workspace_id = :'ws_ep' and slug='chan-ep' \gset
select set_config('test.ch_ep', :'id', false);
select public.approve_channel(:'id');   -- Gate 0: ต้อง approved ก่อนสร้าง episode

insert into public.episodes (channel_id, title) values (:'id','EP1');
insert into public.episodes (channel_id, title) values (:'id','EP2');
select id from public.episodes where channel_id = :'id' and title='EP1' \gset
select set_config('test.ep1', :'id', false);
select id from public.episodes where channel_id = current_setting('test.ch_ep')::uuid and title='EP2' \gset
select set_config('test.ep2', :'id', false);

-- ── (ก) valid: draft→scripted ผ่าน + status เปลี่ยน ───────────────────
select public.transition_episode(current_setting('test.ep1')::uuid, 'scripted');
do $$
declare st public.episode_status;
begin
  select status into st from public.episodes where id = current_setting('test.ep1')::uuid;
  if st <> 'scripted' then raise exception 'FAIL: draft→scripted ไม่เปลี่ยน (เป็น %)', st; end if;
end $$;

-- audit row ต้องเกิด (episode.transition, from=draft,to=scripted) — A เห็น audit ของ workspace ตัวเอง
do $$
declare m jsonb;
begin
  select metadata into m from public.audit_logs
   where action='episode.transition' and entity_id = current_setting('test.ep1')::uuid limit 1;
  if m is null then raise exception 'FAIL: ไม่มี audit row episode.transition'; end if;
  if (m->>'from') <> 'draft' or (m->>'to') <> 'scripted' then
    raise exception 'FAIL: audit metadata ผิด: %', m;
  end if;
end $$;

-- ── (ข) invalid: draft→published (ข้ามขั้น) → raise ──────────────────
do $$
declare blocked boolean := false;
begin
  begin
    perform public.transition_episode(current_setting('test.ep2')::uuid, 'published');
  exception when raise_exception then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: invalid transition draft→published ไม่ถูกกัน'; end if;
end $$;

-- ── (จ-2) publish จาก non-ready (in_production→published) → blocked ───
-- เดิน ep2: draft→scripted→in_production ก่อน แล้วลอง →published
select public.transition_episode(current_setting('test.ep2')::uuid, 'scripted');
select public.transition_episode(current_setting('test.ep2')::uuid, 'in_production');
do $$
declare blocked boolean := false;
begin
  begin
    perform public.transition_episode(current_setting('test.ep2')::uuid, 'published');
  exception when raise_exception then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: publish จาก in_production (non-ready) ไม่ถูกกัน'; end if;
end $$;

-- ── (ค) UPDATE episodes.status ตรง → blocked (trigger) ───────────────
do $$
declare blocked boolean := false;
begin
  begin
    update public.episodes set status='ready' where id = current_setting('test.ep1')::uuid;
  exception when raise_exception then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: UPDATE status ตรงได้ (ต้องผ่าน transition_episode)'; end if;
end $$;

-- ── (จ-1) {any}→archived ผ่าน (จาก scripted) ─────────────────────────
select public.transition_episode(current_setting('test.ep1')::uuid, 'archived');
do $$
declare st public.episode_status;
begin
  select status into st from public.episodes where id = current_setting('test.ep1')::uuid;
  if st <> 'archived' then raise exception 'FAIL: {any}→archived ไม่ทำงาน (เป็น %)', st; end if;
end $$;

-- ═══ (ง) B (ไม่ใช่ member): เรียก transition → raise (has_channel_write) ═══
select set_config('request.jwt.claims','{"sub":"22222222-2222-2222-2222-222222222222"}',false);
do $$
declare denied boolean := false;
begin
  begin
    perform public.transition_episode(current_setting('test.ep2')::uuid, 'qc');
  exception when raise_exception then denied := true;
  end;
  if not denied then raise exception 'FAIL: non-writer เปลี่ยนสถานะ episode ได้'; end if;
end $$;

-- ═══════════════════════════════════════════════════════════════════════
-- (ฉ/ช) DELETE episode — สิทธิ์ผ่าน RLS ล้วน (owner/editor ลบได้ · viewer 0 แถว) + cascade
-- ═══════════════════════════════════════════════════════════════════════
-- เพิ่มผู้ใช้: editor + viewer (insert auth.users ทำในฐานะ postgres)
reset role;
insert into auth.users (id) values
  ('33333333-3333-3333-3333-333333333333'),   -- editor
  ('44444444-4444-4444-4444-444444444444')    -- viewer
on conflict do nothing;

-- owner A เพิ่มสมาชิก editor/viewer + สร้าง character + 3 ตอนสำหรับทดสอบลบ
set role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111"}',false);
insert into public.workspace_members (workspace_id, user_id, role) values
  (:'ws_ep', '33333333-3333-3333-3333-333333333333', 'editor'),
  (:'ws_ep', '44444444-4444-4444-4444-444444444444', 'viewer');

insert into public.characters (channel_id, name, slug)
  values (current_setting('test.ch_ep')::uuid, 'CH-DEL', 'ch-del');
select id from public.characters where channel_id=current_setting('test.ch_ep')::uuid and slug='ch-del' \gset
select set_config('test.char_del', :'id', false);

insert into public.episodes (channel_id, title) values
  (current_setting('test.ch_ep')::uuid, 'EP-DEL-1'),
  (current_setting('test.ch_ep')::uuid, 'EP-DEL-2'),
  (current_setting('test.ch_ep')::uuid, 'EP-DEL-3');
select id from public.episodes where channel_id=current_setting('test.ch_ep')::uuid and title='EP-DEL-1' \gset
select set_config('test.epd1', :'id', false);
select id from public.episodes where channel_id=current_setting('test.ch_ep')::uuid and title='EP-DEL-2' \gset
select set_config('test.epd2', :'id', false);
select id from public.episodes where channel_id=current_setting('test.ch_ep')::uuid and title='EP-DEL-3' \gset
select set_config('test.epd3', :'id', false);

-- ผูก character เข้ากับ EP-DEL-1 (ทดสอบ cascade ON DELETE)
insert into public.episode_characters (episode_id, character_id)
  values (current_setting('test.epd1')::uuid, current_setting('test.char_del')::uuid);

-- ── (ฉ-1) owner ลบ EP-DEL-1 → 1 แถว ──────────────────────────────────
do $$
declare n int;
begin
  delete from public.episodes where id = current_setting('test.epd1')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL: owner ลบ episode ไม่สำเร็จ (row_count=%)', n; end if;
end $$;

-- ตรวจ cascade + การลบจริง ในฐานะ postgres (ข้าม RLS — พิสูจน์ลบจริง ไม่ใช่ RLS ซ่อน)
reset role;
do $$
declare n int;
begin
  select count(*) into n from public.episodes where id = current_setting('test.epd1')::uuid;
  if n <> 0 then raise exception 'FAIL: episode ยังอยู่หลัง owner ลบ (%)', n; end if;
  select count(*) into n from public.episode_characters where episode_id = current_setting('test.epd1')::uuid;
  if n <> 0 then raise exception 'FAIL: cascade ไม่ลบ episode_characters (เหลือ %)', n; end if;
end $$;

-- ── (ฉ-2) editor ลบ EP-DEL-2 → 1 แถว ─────────────────────────────────
set role authenticated;
select set_config('request.jwt.claims','{"sub":"33333333-3333-3333-3333-333333333333"}',false);
do $$
declare n int;
begin
  delete from public.episodes where id = current_setting('test.epd2')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL: editor ลบ episode ไม่สำเร็จ (row_count=%)', n; end if;
end $$;

-- ── (ช) viewer ลบ EP-DEL-3 → 0 แถว (RLS บล็อก ไม่ error) ──────────────
select set_config('request.jwt.claims','{"sub":"44444444-4444-4444-4444-444444444444"}',false);
do $$
declare n int;
begin
  delete from public.episodes where id = current_setting('test.epd3')::uuid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: viewer ลบ episode ได้ (row_count=%) — RLS ต้องบล็อก', n; end if;
end $$;

-- ยืนยัน EP-DEL-3 ยังอยู่จริง (ฐานะ postgres)
reset role;
do $$
declare n int;
begin
  select count(*) into n from public.episodes where id = current_setting('test.epd3')::uuid;
  if n <> 1 then raise exception 'FAIL: EP-DEL-3 หาย ทั้งที่ viewer ลบไม่ได้ (%)', n; end if;
end $$;

reset role;
\echo '========================================='
\echo 'EPISODE STATE-TRANSITION HARNESS PASSED'
\echo '========================================='
