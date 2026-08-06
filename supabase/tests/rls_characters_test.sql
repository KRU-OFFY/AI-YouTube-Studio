-- Characters (Character Bible) RLS + seed harness — docs/05 §5 (migration 0011)
-- ต้องรันตามลำดับ: _supabase_shim.sql → 0001..0011 → ไฟล์นี้
-- พิสูจน์: (ก) seed_puifun count=4 + ดาวดวงน้อย=brand_motif · อีก 3=character
--          (ข) enum type นอก set → error
--          (ค) workspace อื่น (B) read/insert/update characters ของ A ไม่ได้
--          (ง) viewer อ่านได้ แต่เขียน (insert/update) ไม่ได้

\set ON_ERROR_STOP on

insert into auth.users (id) values
  ('a1111111-1111-1111-1111-111111111111'),
  ('b2222222-2222-2222-2222-222222222222'),
  ('c3333333-3333-3333-3333-333333333333')
on conflict do nothing;

-- ═══ A (owner): seed_puifun → workspace + channel + 4 characters ═══
set role authenticated;
select set_config('request.jwt.claims','{"sub":"a1111111-1111-1111-1111-111111111111"}',false);
select (public.seed_puifun()).id as ch_a \gset
select set_config('test.ch_a', :'ch_a', false);
select set_config('test.ws_a',
  (select workspace_id from public.channels where id = :'ch_a')::text, false);

-- (ก) count = 4 + type ถูก
do $$
declare n int; t_motif public.character_type; n_char int;
begin
  select count(*) into n from public.characters where channel_id = current_setting('test.ch_a')::uuid;
  if n <> 4 then raise exception 'FAIL: seed characters ควร = 4 (เห็น %)', n; end if;

  select type into t_motif from public.characters
    where channel_id = current_setting('test.ch_a')::uuid and slug = 'dao-duang-noi';
  if t_motif <> 'brand_motif' then raise exception 'FAIL: ดาวดวงน้อย ควร brand_motif (เป็น %)', t_motif; end if;

  select count(*) into n_char from public.characters
    where channel_id = current_setting('test.ch_a')::uuid and type = 'character';
  if n_char <> 3 then raise exception 'FAIL: character type ควร 3 ตัว (เห็น %)', n_char; end if;
end $$;

select id from public.characters
  where channel_id = current_setting('test.ch_a')::uuid and slug='nong-pui' \gset
select set_config('test.char_a', :'id', false);

-- (ข) enum type นอก set → error
do $$
declare ch uuid := current_setting('test.ch_a')::uuid; blocked boolean := false;
begin
  begin
    insert into public.characters (channel_id, name, slug, type)
      values (ch, 'ผิด', 'wrong-type', 'villain');
  exception when invalid_text_representation or others then blocked := true;
  end;
  if not blocked then raise exception 'FAIL: insert type นอก enum ได้ (ควร error)'; end if;
end $$;

-- ═══ B (คนละ workspace, non-member): เข้าถึงของ A ไม่ได้ ═══
select set_config('request.jwt.claims','{"sub":"b2222222-2222-2222-2222-222222222222"}',false);
do $$
declare ch uuid := current_setting('test.ch_a')::uuid;
        cid uuid := current_setting('test.char_a')::uuid; n int; denied boolean := false;
begin
  select count(*) into n from public.characters where channel_id = ch;
  if n <> 0 then raise exception 'FAIL: B เห็น characters ของ A (% แถว)', n; end if;

  begin
    insert into public.characters (channel_id, name, slug, type) values (ch, 'hack', 'hack-b', 'character');
  exception when others then denied := true;
  end;
  if not denied then raise exception 'FAIL: B แทรก character เข้า channel A ได้'; end if;

  update public.characters set name = 'hacked-by-B' where id = cid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: B แก้ character ของ A ได้ (% แถว)', n; end if;
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
        cid uuid := current_setting('test.char_a')::uuid; n int; denied boolean := false;
begin
  select count(*) into n from public.characters where id = cid;
  if n <> 1 then raise exception 'FAIL: viewer ควรอ่าน character ได้ (เห็น %)', n; end if;

  begin
    insert into public.characters (channel_id, name, slug, type) values (ch, 'v', 'v-char', 'character');
  exception when others then denied := true;
  end;
  if not denied then raise exception 'FAIL: viewer แทรก character ได้'; end if;

  update public.characters set name = 'v-edit' where id = cid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: viewer แก้ character ได้ (% แถว)', n; end if;
end $$;

reset role;
\echo '========================================='
\echo 'CHARACTERS RLS + BIBLE SEED HARNESS PASSED'
\echo '========================================='
