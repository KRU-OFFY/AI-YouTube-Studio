-- TOFFY AI YouTube Studio — seed data (Puifun)
-- ที่มา: docs/05-SEED-DATA.md + docs/pilots/*
-- ครอบคลุมตาราง content_pillars / characters / episodes ตาม schema migration 0001
-- ปลอดภัยต่อการรันซ้ำ: pillars/characters ใช้ ON CONFLICT, episodes ใช้ WHERE NOT EXISTS
--
-- วิธีรัน:
--   * Supabase Dashboard → SQL Editor → วางไฟล์นี้ → Run (หลังรัน migration 0001 แล้ว)
--   * หรือ CLI: supabase db reset  (จะรัน migrations + seed.sql อัตโนมัติ)

set search_path = public;

-- ── 1) Content pillars ──────────────────────────────────────────────
insert into content_pillars (name, description) values
  ('นิทานก่อนนอนสอนใจ', 'P1 · long_form · 4–7 นาที · KPI: rewatch rate, retention 30 วิ'),
  ('เพลง sing-along',    'P2 · long_form · 2–4 นาที · KPI: completion rate, rewatch'),
  ('มุกสั้น/ทายอะไรเอ่ย', 'P3 · shorts · 15–40 วิ · KPI: views, subs per 1,000 views')
on conflict (name) do nothing;

-- ── 2) Characters (Character Bible) ─────────────────────────────────
insert into characters (name, slug, description, image_prompt) values
  ('น้องปุย', 'nong-pui',
   'ตัวเอก/ตัวแทนเด็กผู้ชม · ก้อนปุยกลมนุ่ม · ขี้สงสัย ใจดี ตื่นเต้นง่าย · ปรากฏทุก pillar (P1,P2,P3)',
   $prompt$a small round fluffy white puff creature, soft cream-white fur, large round dark brown eyes with single highlight, soft pink cheeks, tiny puff nubs instead of arms, no mouth teeth, pastel storybook illustration, soft rounded edges, gentle lighting, no text$prompt$),
  ('มุ่ย', 'muui',
   'พี่/ผู้ให้คำตอบและปลอบใจ · เม่นน้อยขนนุ่มไม่แหลม ผ้าพันคอเขียวมิ้นต์ · รอบคอบ อ่อนโยน · P1,P2,P3',
   $prompt$a small gentle hedgehog with soft rounded fluffy quills (not sharp), light warm brown fur, mint green scarf, kind narrow eyes, pastel storybook illustration, soft rounded edges, no text$prompt$),
  ('กัปตันโก๊ะ', 'kaptan-goh',
   'ตัวสร้างเสียงหัวเราะ/สะพานสู่กลุ่ม 6–9 ปี · กบเขียวหมวกใบไม้ · จอมกวน พลังงานสูง · P2,P3 (ห้ามปรากฏใน P1)',
   $prompt$a tiny cheerful green frog wearing a small leaf hat, big smile, expressive eyebrows, pastel storybook illustration, soft rounded edges, no text$prompt$),
  ('ดาวดวงน้อย', 'dao-duang-noi',
   'brand motif (ไม่ใช่ตัวละครพูดได้) · ปิดท้ายนิทาน P1 ทุกตอน · ดาวห้าแฉกเหลืองนวลเรืองแสงนุ่ม ลอยลงมาห่มผ้า',
   $prompt$a small soft glowing pale yellow five-point star, warm gentle light, floating down, pastel night sky background, no text$prompt$)
on conflict (slug) do nothing;

-- ── 3) Episodes (Idea Backlog 10 ตอน) ───────────────────────────────
-- helper: map ชื่อ pillar → id ผ่าน subquery (content_pillars.name เป็น unique)

-- #1 · P2 · มีบทเพลงเต็ม (Pilot #1) → status scripted
insert into episodes (title, pillar_id, status, script, seed_data)
select $t$เพลงธีม "สวัสดีทุ่งปุยฝัน"$t$,
       (select id from content_pillars where name = 'เพลง sing-along'),
       'scripted',
       $script$[Intro - พูดกระซิบเบา ๆ]
ชู่~... หลับตาลงสักครู่นะจ๊ะ...
แล้วตามน้องปุยไปเที่ยวกันเถอะ...

[Verse 1]
ที่ทุ่งแห่งนี้ นุ่มฟูดังปุย
มีดาวน้อยส่องแสง อยู่กลางฟ้าใส
สายลมพัดเบา กล่อมให้ใจสบาย
ที่นี่คือบ้าน ทุ่งปุยฝัน

[Chorus]
สวัสดีจ้า ทุ่งปุยฝัน (ปุย~ ฝัน~ ฝัน~)
ที่ที่ความฝัน ลอยละล่องมา
สวัสดีจ้า ทุ่งปุยฝัน (ปุย~ ฝัน~ ฝัน~)
มาเล่นกับเรา มากอดกันนะ

[Verse 2]
น้องปุยตัวกลม นุ่มนิ่มสีขาว
ตากลมโตใส ยิ้มร่าเริงเบาบาง
ชอบถามชอบมอง ทุกสิ่งรอบกาย
คือเพื่อนตัวน้อย ที่แสนน่ารัก

[Verse 3]
มุ่ยเม่นน้อยนุ่ม ใจดีอ่อนโยน
คอยดูแลเพื่อน ไม่เคยงอนใคร
ผ้าพันคอเขียว โบกไสวตามลม
คือพี่ใจดี แสนอบอุ่น

[Outro - ช้าลง เบาลง]
สวัสดีจ้า ทุ่งปุยฝัน (ปุย... ฝัน... ฝัน...)
ฝันดีนะจ๊ะ ราตรีสวัสดิ์
พรุ่งนี้เช้า เรามาเจอกันใหม่
ที่ทุ่งปุยฝัน รอเธออยู่นะ

— ดูฉบับเต็ม + Suno style prompt ที่ docs/pilots/pilot-01-theme-song.md$script$,
       '{"backlog_no":1,"format":"long_form","characters":["น้องปุย","มุ่ย"],"scores":{"demand":5,"originality":5,"reuse":5,"cost":2},"doc":"docs/pilots/pilot-01-theme-song.md"}'::jsonb
where not exists (select 1 from episodes where title = $t$เพลงธีม "สวัสดีทุ่งปุยฝัน"$t$);

-- #2 · P1 · มีบทเต็ม (Pilot #2) → status scripted
insert into episodes (title, pillar_id, status, script, seed_data)
select $t$นิทาน "ปุยของหนูหายไปไหน"$t$,
       (select id from content_pillars where name = 'นิทานก่อนนอนสอนใจ'),
       'scripted',
       $script$Hook (0:00–0:10):
"มีใครเคยหาของชิ้นโปรดไม่เจอบ้างไหมจ๊ะ? คืนนี้ น้องปุยก็กำลังหาของชิ้นโปรดอยู่เหมือนกันเลย..."

Beat Sheet: Setup → Problem → Support → Search x3 → Climax → Resolution → Lesson → Signature closing (ดาวดวงน้อย)
ธีม: ความกล้าหาญเล็ก ๆ + การขอความช่วยเหลือจากเพื่อน

— ดูบทเต็ม (dialogue ทุกฉาก + Voice Notes + Mini Prompt Pack) ที่ docs/pilots/pilot-02-pui-lost-blanket.md$script$,
       '{"backlog_no":2,"format":"long_form","theme":"ความกล้าหาญ","characters":["น้องปุย","มุ่ย"],"scores":{"demand":5,"originality":4,"reuse":4,"cost":3},"doc":"docs/pilots/pilot-02-pui-lost-blanket.md"}'::jsonb
where not exists (select 1 from episodes where title = $t$นิทาน "ปุยของหนูหายไปไหน"$t$);

-- #3–#10 · ยังเป็นไอเดีย (status draft)
insert into episodes (title, pillar_id, status, seed_data)
select v.title,
       (select id from content_pillars where name = v.pillar_name),
       'draft',
       v.seed_data::jsonb
from (values
  ('เพลง ก-ฮ ฉบับทุ่งปุยฝัน', 'เพลง sing-along',
     '{"backlog_no":3,"format":"long_form","scores":{"demand":5,"originality":3,"reuse":5,"cost":3}}'),
  ($$นิทาน "มุ่ยแบ่งขนมให้น้องปุย"$$, 'นิทานก่อนนอนสอนใจ',
     '{"backlog_no":4,"format":"long_form","theme":"การแบ่งปัน","scores":{"demand":4,"originality":4,"reuse":4,"cost":3}}'),
  ('เพลงนับเลข 1–10 กับก้อนปุยลอย', 'เพลง sing-along',
     '{"backlog_no":5,"format":"long_form","scores":{"demand":5,"originality":3,"reuse":5,"cost":2}}'),
  ($$"กัปตันโก๊ะกระโดดพลาด"$$, 'มุกสั้น/ทายอะไรเอ่ย',
     '{"backlog_no":6,"format":"shorts","scores":{"demand":4,"originality":4,"reuse":3,"cost":1}}'),
  ($$"ทายเสียงสัตว์ในทุ่ง"$$, 'มุกสั้น/ทายอะไรเอ่ย',
     '{"backlog_no":7,"format":"shorts","scores":{"demand":4,"originality":3,"reuse":4,"cost":1}}'),
  ($$"หลับฝันดีนะ" คลิปสงบ 30 วิ$$, 'มุกสั้น/ทายอะไรเอ่ย',
     '{"backlog_no":8,"format":"shorts","scores":{"demand":3,"originality":5,"reuse":5,"cost":1}}'),
  ($$"หน้าตลก ๆ ของน้องปุย"$$, 'มุกสั้น/ทายอะไรเอ่ย',
     '{"backlog_no":9,"format":"shorts","scores":{"demand":4,"originality":4,"reuse":3,"cost":1}}'),
  ($$นิทาน "คืนที่ดาวหล่นลงมา"$$, 'นิทานก่อนนอนสอนใจ',
     '{"backlog_no":10,"format":"long_form","theme":"ความกลัวมืด","scores":{"demand":5,"originality":5,"reuse":4,"cost":3}}')
) as v(title, pillar_name, seed_data)
where not exists (select 1 from episodes e where e.title = v.title);
