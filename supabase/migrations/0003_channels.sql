-- TOFFY AI YouTube Studio — Task 1.3
-- channels + Gate 0 + forbidden_words + ผูก content เข้ากับ channel (channel-scoped) + RLS
--
-- หลักความปลอดภัย (ต่อจาก 1.2):
-- * Gate 0 บังคับที่ DB ด้วย BEFORE INSERT trigger บน episodes (บังคับทุกเส้นทาง)
-- * ทุกฟังก์ชัน SECURITY DEFINER SET search_path='' + อ้างชื่อเต็ม (กัน search_path hijacking)
-- * pillars/characters/episodes สืบทอด scope ผ่าน channel→workspace (RLS)
--
-- ADR-003: rename rights_log → rights_records
-- ADR-004: content เป็น channel-scoped (pillars/characters/episodes.channel_id → channels)
-- AGENTS ข้อ 13: rename content_pillars → pillars

set search_path = public;

-- ── ADR-003 / AGENTS ข้อ 13: rename ตารางให้ตรงกฎ naming ─────────────
alter table content_pillars rename to pillars;
alter table pillars drop constraint if exists content_pillars_name_key;

alter table rights_log rename to rights_records;
alter index if exists rights_log_asset_idx rename to rights_records_asset_idx;
alter table characters drop constraint if exists characters_slug_key;

-- ── enum สถานะ channel ───────────────────────────────────────────────
do $$ begin
  create type channel_status as enum ('draft', 'approved');
exception when duplicate_object then null; end $$;

-- ── ตาราง channels ───────────────────────────────────────────────────
create table if not exists channels (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  name text not null,
  slug text not null,
  handle text,
  primary_language text not null default 'th',
  made_for_kids_default boolean not null default true,       -- ตาม docs/05
  audience_age_range text,
  tone_of_voice text,
  visual_style text,
  publishing_cadence text,
  forbidden_elements jsonb not null default '[]'::jsonb,      -- metadata เชิงพรรณนา
  status channel_status not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, slug)
);
create index if not exists channels_workspace_idx on channels(workspace_id);

drop trigger if exists channels_set_updated_at on channels;
create trigger channels_set_updated_at
  before update on channels
  for each row execute function public.set_updated_at();

-- ── ตาราง forbidden_words (ADR-002: config แยกตาราง ไม่ hard-code) ────
create table if not exists forbidden_words (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references channels(id) on delete cascade,
  word text not null,
  created_at timestamptz not null default now(),
  unique (channel_id, word)
);
create index if not exists forbidden_words_channel_idx on forbidden_words(channel_id);

-- ── ADR-004: ผูก content เข้ากับ channel ─────────────────────────────
-- channel_id เป็น nullable ก่อน (กันข้อมูล flat เดิมหาย) — seed_puifun จะ backfill
alter table pillars     add column if not exists channel_id uuid references channels(id) on delete cascade;
alter table characters  add column if not exists channel_id uuid references channels(id) on delete cascade;
alter table episodes    add column if not exists channel_id uuid references channels(id) on delete cascade;

create index if not exists pillars_channel_idx on pillars(channel_id);
create index if not exists characters_channel_idx on characters(channel_id);
create index if not exists episodes_channel_idx on episodes(channel_id);

-- unique เป็น channel-scoped
create unique index if not exists pillars_channel_name_key on pillars(channel_id, name);
create unique index if not exists characters_channel_slug_key on characters(channel_id, slug);

-- ── helper functions (SECURITY DEFINER — กัน RLS recursion) ───────────
-- true ถ้า auth.uid() เป็น member ของ workspace ที่เป็นเจ้าของ channel ch
create or replace function public.can_access_channel(ch uuid)
returns boolean language sql security definer set search_path = '' stable as $$
  select exists (
    select 1
    from public.channels c
    join public.workspace_members m on m.workspace_id = c.workspace_id
    where c.id = ch and m.user_id = auth.uid()
  );
$$;

-- true ถ้า auth.uid() เป็น member role in (owner,editor) ของ workspace ของ channel ch
create or replace function public.has_channel_write(ch uuid)
returns boolean language sql security definer set search_path = '' stable as $$
  select exists (
    select 1
    from public.channels c
    join public.workspace_members m on m.workspace_id = c.workspace_id
    where c.id = ch and m.user_id = auth.uid() and m.role in ('owner', 'editor')
  );
$$;

-- ── Gate 0: บังคับที่ DB — สร้าง episode ไม่ได้ถ้า channel ยังไม่ approved ─
create or replace function public.enforce_channel_approved()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.channel_id is null then
    raise exception 'episode ต้องผูก channel ก่อน (Gate 0)';
  end if;
  if (select status from public.channels where id = new.channel_id)
       is distinct from 'approved' then
    raise exception 'channel ยังไม่อนุมัติ (Gate 0) — สร้าง episode ไม่ได้';
  end if;
  return new;
end $$;

drop trigger if exists episodes_gate0 on episodes;
create trigger episodes_gate0
  before insert on episodes
  for each row execute function public.enforce_channel_approved();

-- ── RPC อนุมัติ channel (เฉพาะ owner) ────────────────────────────────
create or replace function public.approve_channel(p_id uuid)
returns public.channels language plpgsql security definer set search_path = '' as $$
declare c public.channels;
begin
  if not public.is_workspace_owner(
       (select workspace_id from public.channels where id = p_id)) then
    raise exception 'เฉพาะ owner อนุมัติ channel ได้';
  end if;
  update public.channels set status = 'approved' where id = p_id returning * into c;
  return c;
end $$;

-- ── เปิด RLS ─────────────────────────────────────────────────────────
alter table channels enable row level security;
alter table forbidden_words enable row level security;
alter table pillars enable row level security;
alter table characters enable row level security;
alter table episodes enable row level security;
-- assets / rights_records: ล็อกไว้ก่อน (deny-all) จนกว่าจะออกแบบ policy เฉพาะ (เฟสถัดไป)
alter table assets enable row level security;
alter table rights_records enable row level security;

-- channels
create policy channels_select on channels for select to authenticated
  using (public.is_workspace_member(workspace_id));
create policy channels_insert on channels for insert to authenticated
  with check (public.is_workspace_owner(workspace_id));
create policy channels_update on channels for update to authenticated
  using (public.is_workspace_owner(workspace_id))
  with check (public.is_workspace_owner(workspace_id));
create policy channels_delete on channels for delete to authenticated
  using (public.is_workspace_owner(workspace_id));

-- forbidden_words
create policy fw_select on forbidden_words for select to authenticated
  using (public.can_access_channel(channel_id));
create policy fw_insert on forbidden_words for insert to authenticated
  with check (public.has_channel_write(channel_id));
create policy fw_update on forbidden_words for update to authenticated
  using (public.has_channel_write(channel_id)) with check (public.has_channel_write(channel_id));
create policy fw_delete on forbidden_words for delete to authenticated
  using (public.has_channel_write(channel_id));

-- pillars / characters / episodes: SELECT=member, WRITE=owner+editor (สืบทอด scope)
create policy pillars_select on pillars for select to authenticated
  using (public.can_access_channel(channel_id));
create policy pillars_write on pillars for all to authenticated
  using (public.has_channel_write(channel_id)) with check (public.has_channel_write(channel_id));

create policy characters_select on characters for select to authenticated
  using (public.can_access_channel(channel_id));
create policy characters_write on characters for all to authenticated
  using (public.has_channel_write(channel_id)) with check (public.has_channel_write(channel_id));

create policy episodes_select on episodes for select to authenticated
  using (public.can_access_channel(channel_id));
create policy episodes_write on episodes for all to authenticated
  using (public.has_channel_write(channel_id)) with check (public.has_channel_write(channel_id));

-- ── สิทธิ์ระดับตาราง/ฟังก์ชันให้ authenticated ───────────────────────
grant select, insert, update, delete on channels, forbidden_words, pillars, characters, episodes to authenticated;
grant execute on function public.can_access_channel(uuid) to authenticated;
grant execute on function public.has_channel_write(uuid) to authenticated;
grant execute on function public.approve_channel(uuid) to authenticated;

-- ── RPC seed_puifun(): owner ที่ล็อกอินเรียกครั้งเดียว (idempotent) ───
-- สร้าง workspace "Puifun Studio" + channel "ปุยฝัน" (approved) + pillars/characters/
-- episodes/forbidden_words ตาม docs/05 โดยผูก channel_id ให้ครบ
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

grant execute on function public.seed_puifun() to authenticated;
