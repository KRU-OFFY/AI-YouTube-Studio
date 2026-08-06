-- episode_characters (m2m) RLS harness — migration 0012
-- ต้องรันตามลำดับ: _supabase_shim.sql → 0001..0012 → ไฟล์นี้
-- พิสูจน์: (ก) link same-channel ผ่าน · (ข) link cross-channel ถูกบล็อกที่ DB (แม้ owner ทั้ง 2 channel)
--          (ค) viewer: SELECT เห็น · INSERT/DELETE ปฏิเสธ · (ง) cross-workspace มองไม่เห็น/เขียนไม่ได้
--          (จ) ลบ character ที่ยังผูก → RESTRICT · unlink ก่อน → ลบได้ · (ฉ) ลบ episode → link cascade หาย

\set ON_ERROR_STOP on

insert into auth.users (id) values
  ('a1111111-1111-1111-1111-111111111111'),
  ('b2222222-2222-2222-2222-222222222222'),
  ('c3333333-3333-3333-3333-333333333333')
on conflict do nothing;

-- ═══ A (owner): workspace + 2 channels (chA approved) + characters + episode ═══
set role authenticated;
select set_config('request.jwt.claims','{"sub":"a1111111-1111-1111-1111-111111111111"}',false);

select (public.create_workspace('WS-EC','Asia/Bangkok','THB')).id as ws \gset
select set_config('test.ws', :'ws', false);

insert into public.channels (workspace_id, name, slug) values (:'ws','Chan A','chan-a');
insert into public.channels (workspace_id, name, slug) values (:'ws','Chan B','chan-b');
select id from public.channels where workspace_id=:'ws' and slug='chan-a' \gset
select set_config('test.chA', :'id', false);
select id from public.channels where workspace_id=:'ws' and slug='chan-b' \gset
select set_config('test.chB', :'id', false);
select public.approve_channel(current_setting('test.chA')::uuid);   -- Gate 0 ให้สร้าง episode ได้

insert into public.characters (channel_id, name, slug) values (current_setting('test.chA')::uuid,'CharA','char-a');
insert into public.characters (channel_id, name, slug) values (current_setting('test.chA')::uuid,'CharA2','char-a2');
insert into public.characters (channel_id, name, slug) values (current_setting('test.chB')::uuid,'CharB','char-b');
select id from public.characters where channel_id=current_setting('test.chA')::uuid and slug='char-a' \gset
select set_config('test.charA', :'id', false);
select id from public.characters where channel_id=current_setting('test.chA')::uuid and slug='char-a2' \gset
select set_config('test.charA2', :'id', false);
select id from public.characters where channel_id=current_setting('test.chB')::uuid and slug='char-b' \gset
select set_config('test.charB', :'id', false);

insert into public.episodes (channel_id, title) values (current_setting('test.chA')::uuid,'EP-A');
select id from public.episodes where channel_id=current_setting('test.chA')::uuid and title='EP-A' \gset
select set_config('test.epA', :'id', false);

-- (ก) link same-channel ผ่าน
insert into public.episode_characters (episode_id, character_id)
  values (current_setting('test.epA')::uuid, current_setting('test.charA')::uuid);
do $$
declare n int;
begin
  select count(*) into n from public.episode_characters where episode_id = current_setting('test.epA')::uuid;
  if n <> 1 then raise exception 'FAIL: link same-channel ไม่สำเร็จ (เห็น %)', n; end if;
end $$;

-- (ข) link cross-channel (episode chA + character chB) → ต้องถูกบล็อก (แม้ A เป็น owner ทั้งคู่)
do $$
declare blocked boolean := false;
begin
  begin
    insert into public.episode_characters (episode_id, character_id)
      values (current_setting('test.epA')::uuid, current_setting('test.charB')::uuid);
  exception when others then blocked := true;   -- RLS with check (same_channel_writable=false)
  end;
  if not blocked then raise exception 'FAIL: link cross-channel ได้ (ต้องบล็อกที่ DB)'; end if;
end $$;

-- (จ-1) ลบ character ที่ยังผูก → RESTRICT
do $$
declare blocked boolean := false;
begin
  begin
    delete from public.characters where id = current_setting('test.charA')::uuid;
  exception when foreign_key_violation then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: ลบ character ที่ยังผูกได้ (ต้อง RESTRICT)'; end if;
end $$;

-- ═══ (ค) viewer C: อ่านได้ เขียนไม่ได้ ═══
reset role;
insert into public.workspace_members (workspace_id, user_id, role)
  values (current_setting('test.ws')::uuid, 'c3333333-3333-3333-3333-333333333333', 'viewer')
on conflict do nothing;

set role authenticated;
select set_config('request.jwt.claims','{"sub":"c3333333-3333-3333-3333-333333333333"}',false);
do $$
declare n int; denied boolean := false;
begin
  select count(*) into n from public.episode_characters where episode_id = current_setting('test.epA')::uuid;
  if n <> 1 then raise exception 'FAIL: viewer ควรเห็น link (เห็น %)', n; end if;

  -- viewer insert (same-channel pair แต่ไม่มี write) → ปฏิเสธ
  begin
    insert into public.episode_characters (episode_id, character_id)
      values (current_setting('test.epA')::uuid, current_setting('test.charA2')::uuid);
  exception when others then denied := true;
  end;
  if not denied then raise exception 'FAIL: viewer link ได้ (ต้องปฏิเสธ)'; end if;

  -- viewer delete → USING has_channel_write=false → 0 rows
  delete from public.episode_characters where episode_id = current_setting('test.epA')::uuid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: viewer ลบ link ได้ (% แถว)', n; end if;
end $$;

-- ═══ (ง) cross-workspace B: มองไม่เห็น + เขียนไม่ได้ ═══
select set_config('request.jwt.claims','{"sub":"b2222222-2222-2222-2222-222222222222"}',false);
do $$
declare n int; denied boolean := false;
begin
  select count(*) into n from public.episode_characters where episode_id = current_setting('test.epA')::uuid;
  if n <> 0 then raise exception 'FAIL: B เห็น link ของ A (% แถว)', n; end if;

  begin
    insert into public.episode_characters (episode_id, character_id)
      values (current_setting('test.epA')::uuid, current_setting('test.charA2')::uuid);
  exception when others then denied := true;
  end;
  if not denied then raise exception 'FAIL: B link เข้า episode ของ A ได้'; end if;
end $$;

-- ═══ (จ-2) unlink ก่อน → ลบ character ได้ ═══
select set_config('request.jwt.claims','{"sub":"a1111111-1111-1111-1111-111111111111"}',false);
do $$
declare n int;
begin
  delete from public.episode_characters
    where episode_id = current_setting('test.epA')::uuid
      and character_id = current_setting('test.charA')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL: owner unlink ไม่สำเร็จ (% แถว)', n; end if;
  -- หลัง unlink ลบ character ได้
  delete from public.characters where id = current_setting('test.charA')::uuid;
end $$;

-- ═══ (ฉ) ลบ episode → link cascade หาย ═══
do $$
declare n int;
begin
  -- re-link charA2 เพื่อทดสอบ cascade
  insert into public.episode_characters (episode_id, character_id)
    values (current_setting('test.epA')::uuid, current_setting('test.charA2')::uuid);
  delete from public.episodes where id = current_setting('test.epA')::uuid;   -- owner delete
  select count(*) into n from public.episode_characters where episode_id = current_setting('test.epA')::uuid;
  if n <> 0 then raise exception 'FAIL: ลบ episode แล้ว link ยังอยู่ (% แถว, ควร cascade)', n; end if;
end $$;

reset role;
\echo '========================================='
\echo 'EPISODE_CHARACTERS (m2m) RLS HARNESS PASSED'
\echo '========================================='
