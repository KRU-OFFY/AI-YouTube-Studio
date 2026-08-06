-- TOFFY AI YouTube Studio — Character Bible (docs/05 §5)
--
-- characters มีอยู่แล้ว (0001 + channel_id/RLS 0003) → migration นี้ ALTER เติมฟิลด์ bible
-- RLS characters_select/characters_write (FOR ALL, has_channel_write) ครอบคอลัมน์ใหม่เอง
-- → ไม่ต้องแตะ policy · reuse image_prompt (= canonical_prompt) · unique(channel_id,slug) มีแล้ว
--
-- brand_motif (ดาวดวงน้อย, 05 §5.4) อยู่ในตาราง characters + field type (ไม่แยกตาราง)
-- appears_in = advisory (text[] 'P1'/'P2'/'P3') ไม่มี FK (pillars key ด้วย UUID/name ไม่มี code)
-- immutable: ไฟล์ใหม่ 0011 · ตารางว่างตอน migrate → default/nullable ปลอดภัย ไม่ backfill

set search_path = public;

do $$ begin
  create type character_type as enum ('character', 'brand_motif');
exception when duplicate_object then null; end $$;

-- ── ALTER characters เติมฟิลด์ bible (reuse image_prompt/name/slug/description/channel_id) ──
alter table characters add column if not exists type character_type not null default 'character';
alter table characters add column if not exists role text;
alter table characters add column if not exists species text;
alter table characters add column if not exists appearance jsonb not null default '{}'::jsonb;
alter table characters add column if not exists voice jsonb not null default '{}'::jsonb;
alter table characters add column if not exists personality text[] not null default '{}';
alter table characters add column if not exists forbidden text[] not null default '{}';
alter table characters add column if not exists appears_in text[] not null default '{}';
alter table characters add column if not exists anchor_image_url text;
alter table characters add column if not exists created_by uuid references auth.users(id);

-- ── seed_puifun: create or replace (pattern 0008) — เติมค่า bible ให้ 4 ตัวเดิม ──
-- (ห้ามแตะ 0003 · body เดิมทั้งหมด เปลี่ยนเฉพาะ characters insert ให้ครบฟิลด์ตาม 05 §5)
create or replace function public.seed_puifun()
returns public.channels language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_ws  uuid;
  v_ch  public.channels;
begin
  if v_uid is null then raise exception 'ต้องเข้าสู่ระบบก่อน seed'; end if;

  select id into v_ws from public.workspaces
    where created_by = v_uid and name = 'Puifun Studio' limit 1;
  if v_ws is null then
    insert into public.workspaces (name, created_by) values ('Puifun Studio', v_uid)
      returning id into v_ws;
    insert into public.workspace_members (workspace_id, user_id, role)
      values (v_ws, v_uid, 'owner');
  end if;

  -- channel ปุยฝัน (ตั้ง flag ก่อน INSERT — trigger 0008 ยอมให้ status<>'draft')
  perform set_config('app.allow_status_change', '1', true);
  insert into public.channels
    (workspace_id, name, slug, handle, made_for_kids_default, status, created_by,
     audience_age_range, tone_of_voice, visual_style, publishing_cadence)
  values
    (v_ws, 'ปุยฝัน', 'puifun', '@puifun', true, 'approved', v_uid,
     '2–5', 'อบอุ่น ช้า นุ่มนวล ไม่กระตุ้น', '2D/2.5D พาสเทล ขอบมน',
     'Long-form 1/สัปดาห์ + Shorts 3/สัปดาห์')
  on conflict (workspace_id, slug) do nothing;
  select * into v_ch from public.channels where workspace_id = v_ws and slug = 'puifun';

  insert into public.pillars (channel_id, name, description) values
    (v_ch.id, 'นิทานก่อนนอนสอนใจ', 'P1 · long_form · 4–7 นาที · KPI: rewatch, retention 30 วิ'),
    (v_ch.id, 'เพลง sing-along',    'P2 · long_form · 2–4 นาที · KPI: completion, rewatch'),
    (v_ch.id, 'มุกสั้น/ทายอะไรเอ่ย', 'P3 · shorts · 15–40 วิ · KPI: views, subs/1k views')
  on conflict (channel_id, name) do nothing;

  -- characters — Character Bible docs/05 §5 (เติม type/role/species/appearance/voice/personality/forbidden/appears_in)
  insert into public.characters
    (channel_id, name, slug, description, image_prompt,
     type, role, species, appearance, voice, personality, forbidden, appears_in) values
    (v_ch.id, 'น้องปุย', 'nong-pui', 'ตัวเอก ก้อนปุยกลมนุ่ม · ปรากฏทุก pillar',
      'a small round fluffy white puff creature, soft cream-white fur, large round dark brown eyes, soft pink cheeks, pastel storybook illustration, no text',
      'character', 'ตัวเอก / ตัวแทนเด็กผู้ชม', 'ก้อนปุย',
      '{"shape":"กลม นุ่ม ไม่มีแขนขาชัดเจน มีติ่งปุยแทนมือ","color_primary":"#FFFFFF ขาวนวล","color_accent":"#FFD3DD แก้มชมพูอ่อน","eyes":"กลมโต สีน้ำตาลเข้ม มีประกายจุดเดียว","size_reference":"เท่าลูกฟุตบอล"}'::jsonb,
      '{"age_impression":"เด็ก 4 ขวบ","pace":"ช้า","tone":"ใส สดใส","emotion_range":["สงสัย","ดีใจ","กลัวนิดหน่อย","อบอุ่น"]}'::jsonb,
      array['ขี้สงสัย','ใจดี','ตื่นเต้นง่าย','ไม่เคยโกรธ'],
      array['ห้ามร้องไห้เสียงดัง','ห้ามโกรธ','ห้ามมีแขนขาแบบมนุษย์'],
      array['P1','P2','P3']),
    (v_ch.id, 'มุ่ย', 'muui', 'พี่ เม่นน้อยขนนุ่ม ผ้าพันคอเขียวมิ้นต์',
      'a small gentle hedgehog with soft rounded fluffy quills, mint green scarf, pastel storybook illustration, no text',
      'character', 'พี่ / ผู้ให้คำตอบและปลอบใจ', 'เม่นน้อย (ขนนุ่มไม่แหลม)',
      '{"color_primary":"#C89B7B น้ำตาลอ่อน","quills":"ขนนุ่มมนเหมือนปุยขนแกะ ไม่แหลมคม","eyes":"เรียวอ่อนโยน","accessory":"ผ้าพันคอสีเขียวมิ้นต์"}'::jsonb,
      '{"age_impression":"เด็ก 7 ขวบ","tone":"นุ่มนวล อบอุ่น"}'::jsonb,
      array['รอบคอบ','อ่อนโยน','ชอบดูแล','พูดช้า'],
      array['ห้ามทำหน้าขนแหลมน่ากลัว','ห้ามดุน้องปุย'],
      array['P1','P2','P3']),
    (v_ch.id, 'กัปตันโก๊ะ', 'kaptan-goh', 'กบเขียวหมวกใบไม้ · P2,P3 (ห้ามใน P1)',
      'a tiny cheerful green frog with a leaf hat, big smile, pastel storybook illustration, no text',
      'character', 'ตัวสร้างเสียงหัวเราะ / สะพานสู่กลุ่ม 6–9 ปี', 'กบเขียวตัวเล็ก',
      '{"color_primary":"#9BD46A เขียวอ่อน","accessory":"หมวกใบไม้","expression":"ยิ้มกว้าง คิ้วขยับเยอะ"}'::jsonb,
      '{"tone":"การ์ตูนกวน จังหวะเร็ว"}'::jsonb,
      array['จอมกวน','พลังงานสูง','ซุ่มซ่าม','ใจดี'],
      array['ห้ามปรากฏในนิทานก่อนนอน (P1)','ห้ามแกล้งจนเพื่อนเสียใจ'],
      array['P2','P3']),
    (v_ch.id, 'ดาวดวงน้อย', 'dao-duang-noi', 'brand motif ปิดท้ายนิทาน P1',
      'a small soft glowing pale yellow five-point star, pastel night sky, no text',
      'brand_motif', 'motif ปิดท้ายนิทานก่อนนอน (signature shot)', 'ดาวห้าแฉก',
      '{"appearance":"ดาวห้าแฉกสีเหลืองนวล เรืองแสงนุ่ม ลอยลงมาห่มผ้าให้ตัวละคร","dialogue":"none"}'::jsonb,
      '{}'::jsonb,
      array[]::text[],
      array[]::text[],
      array['P1'])
  on conflict (channel_id, slug) do nothing;

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

  insert into public.forbidden_words (channel_id, word)
  select v_ch.id, w from unnest(array[
    'ตาย','ฆ่า','ผี','น่ากลัว','โง่','อ้วน','ขี้เหร่','เกลียด','ซื้อเลย','กดสั่ง','ราคาพิเศษ'
  ]) as w
  on conflict (channel_id, word) do nothing;

  return v_ch;
end $$;
