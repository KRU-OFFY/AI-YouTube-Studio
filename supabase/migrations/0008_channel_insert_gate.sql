-- TOFFY AI YouTube Studio — ปิด M-new: Gate 0 INSERT-bypass ที่ตาราง channels
--
-- เดิม channels_status_guard (0006) เป็น BEFORE UPDATE เท่านั้น → owner ยัง INSERT
-- channel เป็น status='approved' ตรงได้ (ข้าม approve_channel → ไม่มี audit channel.approve)
-- = Gate 0 bypass ทาง INSERT (คู่กับ M1 คนละ path)
--
-- แก้: trigger BEFORE INSERT บังคับ channel เกิดใหม่ต้องเป็น 'draft'
-- อนุมัติได้ทางเดียวผ่าน approve_channel (ซึ่งตั้ง GUC app.allow_status_change='1')
-- reuse GUC flag เดียวกับ M1 → คุม status ทั้ง INSERT + UPDATE ทางเดียวกัน
--
-- immutable: ไม่แตะ 0003/0006/0007 → seed_puifun ใช้ create or replace ที่นี่
-- (seed insert channel 'approved' ตรง → ต้องตั้ง flag ก่อน INSERT ไม่งั้น trigger เด้ง)

set search_path = public;

-- ── [M-new] บังคับ channel เกิดใหม่เป็น draft ─────────────────────────
create or replace function public.channels_guard_insert_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status is distinct from 'draft'
     and coalesce(current_setting('app.allow_status_change', true), '') <> '1' then
    raise exception 'สร้าง channel ต้องเป็น draft — อนุมัติผ่าน approve_channel เท่านั้น (Gate 0)';
  end if;
  return new;
end $$;

drop trigger if exists channels_insert_status_guard on channels;
create trigger channels_insert_status_guard
  before insert on channels
  for each row execute function public.channels_guard_insert_status();

-- ── แก้ seed_puifun: ตั้ง flag ก่อน INSERT channels ('approved') ───────
-- create or replace รักษา grant/revoke เดิมจาก 0003 (สำเนา body ครบ + เพิ่ม set_config)
create or replace function public.seed_puifun()
returns public.channels language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_ws  uuid;
  v_ch  public.channels;
begin
  if v_uid is null then raise exception 'ต้องเข้าสู่ระบบก่อน seed'; end if;

  -- workspace (get-or-create)
  select id into v_ws from public.workspaces
    where created_by = v_uid and name = 'Puifun Studio' limit 1;
  if v_ws is null then
    insert into public.workspaces (name, created_by) values ('Puifun Studio', v_uid)
      returning id into v_ws;
    insert into public.workspace_members (workspace_id, user_id, role)
      values (v_ws, v_uid, 'owner');
  end if;

  -- channel "ปุยฝัน" (approved เพื่อให้ seed episode ผ่าน Gate 0)
  -- ตั้ง flag ก่อน INSERT — trigger channels_insert_status_guard (0008) ยอมให้ status<>'draft'
  perform set_config('app.allow_status_change', '1', true); -- local ต่อ transaction
  insert into public.channels
    (workspace_id, name, slug, handle, made_for_kids_default, status, created_by,
     audience_age_range, tone_of_voice, visual_style, publishing_cadence)
  values
    (v_ws, 'ปุยฝัน', 'puifun', '@puifun', true, 'approved', v_uid,
     '2–5', 'อบอุ่น ช้า นุ่มนวล ไม่กระตุ้น', '2D/2.5D พาสเทล ขอบมน',
     'Long-form 1/สัปดาห์ + Shorts 3/สัปดาห์')
  on conflict (workspace_id, slug) do nothing;
  select * into v_ch from public.channels where workspace_id = v_ws and slug = 'puifun';

  -- pillars
  insert into public.pillars (channel_id, name, description) values
    (v_ch.id, 'นิทานก่อนนอนสอนใจ', 'P1 · long_form · 4–7 นาที · KPI: rewatch, retention 30 วิ'),
    (v_ch.id, 'เพลง sing-along',    'P2 · long_form · 2–4 นาที · KPI: completion, rewatch'),
    (v_ch.id, 'มุกสั้น/ทายอะไรเอ่ย', 'P3 · shorts · 15–40 วิ · KPI: views, subs/1k views')
  on conflict (channel_id, name) do nothing;

  -- characters
  insert into public.characters (channel_id, name, slug, description, image_prompt) values
    (v_ch.id, 'น้องปุย', 'nong-pui', 'ตัวเอก ก้อนปุยกลมนุ่ม · ปรากฏทุก pillar',
      'a small round fluffy white puff creature, soft cream-white fur, large round dark brown eyes, soft pink cheeks, pastel storybook illustration, no text'),
    (v_ch.id, 'มุ่ย', 'muui', 'พี่ เม่นน้อยขนนุ่ม ผ้าพันคอเขียวมิ้นต์',
      'a small gentle hedgehog with soft rounded fluffy quills, mint green scarf, pastel storybook illustration, no text'),
    (v_ch.id, 'กัปตันโก๊ะ', 'kaptan-goh', 'กบเขียวหมวกใบไม้ · P2,P3 (ห้ามใน P1)',
      'a tiny cheerful green frog with a leaf hat, big smile, pastel storybook illustration, no text'),
    (v_ch.id, 'ดาวดวงน้อย', 'dao-duang-noi', 'brand motif ปิดท้ายนิทาน P1',
      'a small soft glowing pale yellow five-point star, pastel night sky, no text')
  on conflict (channel_id, slug) do nothing;

  -- episodes (10 จาก idea backlog) — ผูก channel + pillar
  insert into public.episodes (channel_id, title, pillar_id, status, seed_data)
  select v_ch.id, v.title,
         (select id from public.pillars p where p.channel_id = v_ch.id and p.name = v.pillar_name),
         v.status::public.episode_status, v.seed_data::jsonb
  from (values
    ('เพลงธีม "สวัสดีทุ่งปุยฝัน"', 'เพลง sing-along', 'scripted',
      '{"backlog_no":1,"format":"long_form","scores":{"demand":5,"originality":5,"reuse":5,"cost":2},"doc":"docs/pilots/pilot-01-theme-song.md"}'),
    ('นิทาน "ปุยของหนูหายไปไหน"', 'นิทานก่อนนอนสอนใจ', 'scripted',
      '{"backlog_no":2,"format":"long_form","scores":{"demand":5,"originality":4,"reuse":4,"cost":3},"doc":"docs/pilots/pilot-02-pui-lost-blanket.md"}'),
    ('เพลง ก-ฮ ฉบับทุ่งปุยฝัน', 'เพลง sing-along', 'draft',
      '{"backlog_no":3,"format":"long_form","scores":{"demand":5,"originality":3,"reuse":5,"cost":3}}'),
    ('นิทาน "มุ่ยแบ่งขนมให้น้องปุย"', 'นิทานก่อนนอนสอนใจ', 'draft',
      '{"backlog_no":4,"format":"long_form","theme":"การแบ่งปัน","scores":{"demand":4,"originality":4,"reuse":4,"cost":3}}'),
    ('เพลงนับเลข 1–10 กับก้อนปุยลอย', 'เพลง sing-along', 'draft',
      '{"backlog_no":5,"format":"long_form","scores":{"demand":5,"originality":3,"reuse":5,"cost":2}}'),
    ('"กัปตันโก๊ะกระโดดพลาด"', 'มุกสั้น/ทายอะไรเอ่ย', 'draft',
      '{"backlog_no":6,"format":"shorts","scores":{"demand":4,"originality":4,"reuse":3,"cost":1}}'),
    ('"ทายเสียงสัตว์ในทุ่ง"', 'มุกสั้น/ทายอะไรเอ่ย', 'draft',
      '{"backlog_no":7,"format":"shorts","scores":{"demand":4,"originality":3,"reuse":4,"cost":1}}'),
    ('"หลับฝันดีนะ" คลิปสงบ 30 วิ', 'มุกสั้น/ทายอะไรเอ่ย', 'draft',
      '{"backlog_no":8,"format":"shorts","scores":{"demand":3,"originality":5,"reuse":5,"cost":1}}'),
    ('"หน้าตลก ๆ ของน้องปุย"', 'มุกสั้น/ทายอะไรเอ่ย', 'draft',
      '{"backlog_no":9,"format":"shorts","scores":{"demand":4,"originality":4,"reuse":3,"cost":1}}'),
    ('นิทาน "คืนที่ดาวหล่นลงมา"', 'นิทานก่อนนอนสอนใจ', 'draft',
      '{"backlog_no":10,"format":"long_form","theme":"ความกลัวมืด","scores":{"demand":5,"originality":5,"reuse":4,"cost":3}}')
  ) as v(title, pillar_name, status, seed_data)
  where not exists (
    select 1 from public.episodes e where e.channel_id = v_ch.id and e.title = v.title
  );

  -- forbidden_words จาก docs/05 หัวข้อ 8
  insert into public.forbidden_words (channel_id, word)
  select v_ch.id, w from unnest(array[
    'ตาย','ฆ่า','ผี','น่ากลัว','โง่','อ้วน','ขี้เหร่','เกลียด','ซื้อเลย','กดสั่ง','ราคาพิเศษ'
  ]) as w
  on conflict (channel_id, word) do nothing;

  return v_ch;
end $$;
