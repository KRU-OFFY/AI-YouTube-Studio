-- ปุยฝัน — schema รวม migration 0001..0012 (สำหรับ paste ใน Supabase SQL editor ครั้งเดียว)
-- generate จาก supabase/migrations/*.sql · รันเป็น postgres/superuser (SQL editor)
-- ไม่รวม seed — seed_puifun + anchor รันแยก (ต้อง impersonate user จริง)


-- ========== 0001_init.sql ==========
-- TOFFY AI YouTube Studio — initial schema
-- แบรนด์: ปุยฝัน (Puifun). Draft version — พร้อมปรับตามงานจริง.

set search_path = public;

create extension if not exists "pgcrypto";

-- content pillars (นิทานก่อนนอน / เพลงร้องตาม / คลิปตลกสั้น ฯลฯ)
create table if not exists content_pillars (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

-- characters (น้องปุย, มุ่ย, กัปตันโก๊ะ, ...)
create table if not exists characters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  image_prompt text,
  created_at timestamptz not null default now()
);

-- episodes
do $$ begin
  create type episode_status as enum (
    'draft',
    'scripted',
    'in_production',
    'qc',
    'ready',
    'published',
    'archived'
  );
exception when duplicate_object then null; end $$;

create table if not exists episodes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  pillar_id uuid references content_pillars(id) on delete set null,
  status episode_status not null default 'draft',
  script text,
  seed_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists episodes_pillar_idx on episodes(pillar_id);
create index if not exists episodes_status_idx on episodes(status);

-- assets ที่ AI สร้าง (ภาพ / เสียง / วิดีโอ)
do $$ begin
  create type asset_type as enum ('image', 'audio', 'video', 'text', 'other');
exception when duplicate_object then null; end $$;

create table if not exists assets (
  id uuid primary key default gen_random_uuid(),
  episode_id uuid references episodes(id) on delete cascade,
  type asset_type not null,
  storage_path text not null,
  source_tool text,
  created_at timestamptz not null default now()
);

create index if not exists assets_episode_idx on assets(episode_id);
create index if not exists assets_type_idx on assets(type);

-- rights log — จดที่มา / prompt / สัญญาอนุญาต ของทุก asset ที่ AI สร้าง
create table if not exists rights_log (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references assets(id) on delete cascade,
  tool_used text not null,
  prompt_used text,
  license_note text,
  generated_at timestamptz not null default now()
);

create index if not exists rights_log_asset_idx on rights_log(asset_id);

-- updated_at trigger สำหรับ episodes
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists episodes_set_updated_at on episodes;
create trigger episodes_set_updated_at
  before update on episodes
  for each row execute function set_updated_at();


-- ========== 0002_workspaces.sql ==========
-- TOFFY AI YouTube Studio — Task 1.2
-- workspaces + workspace_members + Row Level Security (FR-001 ตาม docs/02)
--
-- หลักความปลอดภัย:
-- * multi-tenancy บังคับที่ระดับ DB ด้วย RLS (ไม่ใช่กรองในโค้ดแอป)
-- * ฟังก์ชัน SECURITY DEFINER ทุกตัว SET search_path = '' และอ้างชื่อเต็ม
--   (public.*, auth.*) เพื่อกัน search_path hijacking
-- * helper is_workspace_member / is_workspace_owner เป็น SECURITY DEFINER
--   เพื่อไม่ให้ policy ของ workspace_members ที่เรียก helper (ซึ่ง query
--   workspace_members เอง) เกิด RLS recursion — definer รันในสิทธิ์เจ้าของตาราง
--   จึงข้าม RLS ภายใน ตัดวงวนได้

set search_path = public;

-- ── enum role ────────────────────────────────────────────────────────
do $$ begin
  create type workspace_role as enum ('owner', 'editor', 'viewer');
exception when duplicate_object then null; end $$;

-- ── ตาราง ────────────────────────────────────────────────────────────
create table if not exists workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  default_language text not null default 'th',
  timezone text not null default 'Asia/Bangkok',
  currency text not null default 'THB',
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role workspace_role not null default 'viewer',
  created_at timestamptz not null default now(),
  unique (workspace_id, user_id)
);

create index if not exists workspace_members_user_idx on workspace_members(user_id);
create index if not exists workspaces_created_by_idx on workspaces(created_by);

-- updated_at trigger (ใช้ฟังก์ชัน set_updated_at จาก migration 0001)
drop trigger if exists workspaces_set_updated_at on workspaces;
create trigger workspaces_set_updated_at
  before update on workspaces
  for each row execute function public.set_updated_at();

-- ── helper functions (SECURITY DEFINER — กัน RLS recursion) ───────────
-- true ถ้า auth.uid() เป็นสมาชิกของ workspace ws
create or replace function public.is_workspace_member(ws uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.workspace_members m
    where m.workspace_id = ws
      and m.user_id = auth.uid()
  );
$$;

-- true ถ้า auth.uid() เป็นสมาชิก role='owner' ของ workspace ws
create or replace function public.is_workspace_owner(ws uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.workspace_members m
    where m.workspace_id = ws
      and m.user_id = auth.uid()
      and m.role = 'owner'
  );
$$;

-- ── RPC สร้าง workspace + เพิ่มตัวเองเป็น owner แถวแรก (atomic) ─────────
-- ทำใน SECURITY DEFINER เพื่อ bootstrap owner แถวแรก โดยไม่ถูก policy
-- "เฉพาะ owner เพิ่มสมาชิกได้" บล็อก (ยังไม่มีใครเป็น owner ตอนสร้าง)
create or replace function public.create_workspace(
  p_name text,
  p_timezone text default 'Asia/Bangkok',
  p_currency text default 'THB'
)
returns public.workspaces
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  w public.workspaces;
begin
  if v_uid is null then
    raise exception 'ต้องเข้าสู่ระบบก่อนสร้าง workspace';
  end if;
  if coalesce(btrim(p_name), '') = '' then
    raise exception 'ชื่อ workspace ห้ามว่าง';
  end if;

  insert into public.workspaces (name, default_language, timezone, currency, created_by)
  values (
    btrim(p_name),
    'th',
    coalesce(nullif(btrim(p_timezone), ''), 'Asia/Bangkok'),
    coalesce(nullif(btrim(p_currency), ''), 'THB'),
    v_uid
  )
  returning * into w;

  insert into public.workspace_members (workspace_id, user_id, role)
  values (w.id, v_uid, 'owner');

  return w;
end;
$$;

-- ── เปิด RLS ─────────────────────────────────────────────────────────
alter table workspaces enable row level security;
alter table workspace_members enable row level security;

-- workspaces
-- SELECT: เห็นเฉพาะ workspace ที่ตัวเองเป็นสมาชิก
create policy workspaces_select on workspaces
  for select to authenticated
  using (public.is_workspace_member(id));
-- (ไม่มี INSERT policy → client insert ตรงไม่ได้ ต้องผ่าน create_workspace)
-- UPDATE: เฉพาะ owner แก้ได้
create policy workspaces_update on workspaces
  for update to authenticated
  using (public.is_workspace_owner(id))
  with check (public.is_workspace_owner(id));
-- DELETE: เฉพาะ owner ลบได้
create policy workspaces_delete on workspaces
  for delete to authenticated
  using (public.is_workspace_owner(id));

-- workspace_members
-- SELECT: สมาชิกเห็นรายชื่อสมาชิกใน workspace เดียวกัน
create policy members_select on workspace_members
  for select to authenticated
  using (public.is_workspace_member(workspace_id));
-- INSERT: เฉพาะ owner เพิ่มสมาชิกได้ (owner แถวแรก bootstrap ผ่าน create_workspace)
create policy members_insert on workspace_members
  for insert to authenticated
  with check (public.is_workspace_owner(workspace_id));
-- UPDATE: เฉพาะ owner แก้ role ได้
create policy members_update on workspace_members
  for update to authenticated
  using (public.is_workspace_owner(workspace_id))
  with check (public.is_workspace_owner(workspace_id));
-- DELETE: เฉพาะ owner ลบสมาชิกได้
create policy members_delete on workspace_members
  for delete to authenticated
  using (public.is_workspace_owner(workspace_id));

-- ── สิทธิ์ระดับตาราง/ฟังก์ชันให้ role authenticated ──────────────────
-- (Supabase ปกติ grant ให้อยู่แล้วผ่าน default privileges — ใส่ชัดเจนเพื่อ
--  ความ deterministic และให้ RLS harness ทดสอบได้ตรงจริง)
grant usage on schema public to authenticated;
grant select, update, delete on workspaces to authenticated;
grant select, insert, update, delete on workspace_members to authenticated;
-- write RPC: revoke default PUBLIC execute ก่อน (กัน anon เรียกสร้าง workspace)
revoke execute on function public.create_workspace(text, text, text) from public;
grant execute on function public.create_workspace(text, text, text) to authenticated;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.is_workspace_owner(uuid) to authenticated;


-- ========== 0003_channels.sql ==========
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
-- write RPC: revoke default PUBLIC execute ก่อน (กัน anon อนุมัติ channel)
revoke execute on function public.approve_channel(uuid) from public;
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

revoke execute on function public.seed_puifun() from public;
grant execute on function public.seed_puifun() to authenticated;


-- ========== 0004_content_channel_not_null.sql ==========
-- TOFFY AI YouTube Studio — Task 1.3 (ต่อจาก 0003)
-- ปิดจบ channel_id ของ content ให้เป็น NOT NULL หลัง backfill
--
-- ลำดับที่ปลอดภัย (ตามที่ฝั่งวางแผนกำชับ):
--   0003 สร้าง channel_id แบบ nullable → owner รัน select public.seed_puifun() (backfill)
--   → 0004 (ไฟล์นี้) SET NOT NULL เมื่อยืนยันไม่มีแถว channel_id ค้าง
--
-- หมายเหตุ: ในโปรเจกต์ใหม่ ตาราง pillars/characters/episodes ว่างตอนรัน migration
-- (seed ทำผ่าน RPC ไม่ใช่ flat insert) → SET NOT NULL ผ่านทันที
-- ถ้ามีแถว channel_id = NULL ค้างอยู่ (เช่นเคยรัน seed flat เก่า) migration นี้จะ error
-- ให้ชัดเจน เพื่อบังคับให้ backfill ก่อน — ไม่ปล่อย orphan หลุด RLS

set search_path = public;

do $$
declare n int;
begin
  select count(*) into n from (
    select 1 from pillars    where channel_id is null
    union all select 1 from characters where channel_id is null
    union all select 1 from episodes   where channel_id is null
  ) t;
  if n > 0 then
    raise exception 'พบ % แถวที่ channel_id ยังเป็น NULL — ต้องรัน seed_puifun()/backfill ก่อน SET NOT NULL', n;
  end if;
end $$;

alter table pillars    alter column channel_id set not null;
alter table characters alter column channel_id set not null;
alter table episodes   alter column channel_id set not null;


-- ========== 0005_audit_logs.sql ==========
-- TOFFY AI YouTube Studio — Task 1.4
-- audit_logs (FR-013) — append-only, ไม่เก็บ secret/PII, RLS ผูก workspace
--
-- หลักความปลอดภัย (Security & Audit standing rules):
-- * APPEND-ONLY จริงที่ DB: ไม่ grant UPDATE/DELETE + trigger BEFORE UPDATE/DELETE → RAISE
-- * เขียนผ่าน RPC/server เท่านั้น: ไม่มี INSERT policy ให้ client; actor = auth.uid() (ปลอมไม่ได้)
-- * ห้าม grant anon EXECUTE log_audit (กัน flood/DoS) — login-failure บันทึกฝั่ง server ด้วย service-role
-- * ฟังก์ชัน SECURITY DEFINER + search_path=''

set search_path = public;

do $$ begin
  create type audit_result as enum ('success', 'failure');
exception when duplicate_object then null; end $$;

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references workspaces(id) on delete cascade,   -- NULL ได้ (เช่น login)
  actor_user_id uuid references auth.users(id) on delete set null, -- NULL ได้ (login-failure)
  action text not null,
  entity_type text,
  entity_id uuid,
  result audit_result not null default 'success',
  metadata jsonb not null default '{}'::jsonb,   -- เฉพาะข้อมูลปลอดภัย (ผ่าน sanitize)
  created_at timestamptz not null default now()
);
create index if not exists audit_logs_ws_created_idx on audit_logs(workspace_id, created_at desc);
create index if not exists audit_logs_actor_idx on audit_logs(actor_user_id);

alter table audit_logs enable row level security;

-- SELECT: member เห็น log ของ workspace ตัวเอง + เหตุการณ์ส่วนตัวของตัวเอง
create policy audit_select on audit_logs for select to authenticated
  using (
    (workspace_id is not null and public.is_workspace_member(workspace_id))
    or actor_user_id = auth.uid()
  );
-- ไม่มี INSERT/UPDATE/DELETE policy → client เขียน/แก้/ลบตรงไม่ได้ (เขียนผ่าน RPC/server)

-- ── APPEND-ONLY hard guarantee: แก้/ลบไม่ได้แม้ role ที่มีสิทธิ์ ─────
create or replace function public.audit_no_mutate()
returns trigger language plpgsql set search_path = '' as $$
begin
  raise exception 'audit_logs เป็น append-only — แก้ไข/ลบไม่ได้';
end $$;

drop trigger if exists audit_logs_no_update on audit_logs;
create trigger audit_logs_no_update before update on audit_logs
  for each row execute function public.audit_no_mutate();
drop trigger if exists audit_logs_no_delete on audit_logs;
create trigger audit_logs_no_delete before delete on audit_logs
  for each row execute function public.audit_no_mutate();

-- ── RPC log_audit: actor = auth.uid() เสมอ (caller ส่ง actor เองไม่ได้) ─
create or replace function public.log_audit(
  p_action text,
  p_entity_type text default null,
  p_entity_id uuid default null,
  p_workspace_id uuid default null,
  p_result audit_result default 'success',
  p_metadata jsonb default '{}'::jsonb
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.audit_logs
    (workspace_id, actor_user_id, action, entity_type, entity_id, result, metadata)
  values
    (p_workspace_id, auth.uid(), p_action, p_entity_type, p_entity_id,
     p_result, coalesce(p_metadata, '{}'::jsonb));
end $$;

-- grant: EXECUTE เฉพาะ authenticated (ไม่ให้ anon เขียน) — SELECT ให้ทั้งคู่ (anon จะได้ 0 แถวจาก RLS)
-- สำคัญ: Postgres grant EXECUTE ให้ PUBLIC โดย default → ต้อง revoke ก่อน ไม่งั้น anon เขียน audit ได้ (flood)
revoke execute on function public.log_audit(text, text, uuid, uuid, public.audit_result, jsonb) from public;
grant execute on function public.log_audit(text, text, uuid, uuid, public.audit_result, jsonb) to authenticated;
grant select on audit_logs to authenticated, anon;


-- ========== 0006_sprint1_hardening.sql ==========
-- TOFFY AI YouTube Studio — Sprint 1 hardening (ปิด finding จากรอบ Audit)
--
-- [H1] audit_logs ปะทะ append-only trigger กับ FK cascade/set-null → ลบ workspace/user ไม่ได้
--      แก้: ตัด FK referential action ออก เก็บ workspace_id/actor_user_id เป็น uuid ประวัติ
--      (ตาราง audit ควรคง id ไว้แม้ entity ถูกลบ — append-only ที่แท้จริง)
-- [M1] อนุมัติ channel ผ่าน UPDATE ตรงได้ → ข้าม approve_channel + ไม่มี audit
--      แก้: trigger กันเปลี่ยน status นอก path ของ approve_channel (บังคับผ่าน RPC + audit)

set search_path = public;

-- ── [H1] ตัด FK ของ audit_logs ─────────────────────────────────────
alter table audit_logs drop constraint if exists audit_logs_workspace_id_fkey;
alter table audit_logs drop constraint if exists audit_logs_actor_user_id_fkey;
comment on column audit_logs.workspace_id is
  'historical workspace id (no FK) — คงไว้เป็นประวัติแม้ workspace ถูกลบ';
comment on column audit_logs.actor_user_id is
  'historical actor id (no FK) — คงไว้เป็นประวัติแม้ user ถูกลบ';

-- ── [M1] กันเปลี่ยน channels.status นอก approve_channel ─────────────
-- อนุญาตเปลี่ยน status ก็ต่อเมื่อมี GUC app.allow_status_change='1' (ตั้งใน approve_channel เท่านั้น)
create or replace function public.channels_guard_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status is distinct from old.status
     and coalesce(current_setting('app.allow_status_change', true), '') <> '1' then
    raise exception 'เปลี่ยนสถานะ channel ต้องผ่าน approve_channel (Gate 0) — เปลี่ยนตรงไม่ได้';
  end if;
  return new;
end $$;

drop trigger if exists channels_status_guard on channels;
create trigger channels_status_guard
  before update on channels
  for each row execute function public.channels_guard_status();

-- ปรับ approve_channel: ตั้ง flag ก่อนเปลี่ยน status (create or replace รักษา grant เดิมไว้)
create or replace function public.approve_channel(p_id uuid)
returns public.channels language plpgsql security definer set search_path = '' as $$
declare c public.channels;
begin
  if not public.is_workspace_owner(
       (select workspace_id from public.channels where id = p_id)) then
    raise exception 'เฉพาะ owner อนุมัติ channel ได้';
  end if;
  perform set_config('app.allow_status_change', '1', true); -- local ต่อ transaction
  update public.channels set status = 'approved' where id = p_id returning * into c;
  return c;
end $$;


-- ========== 0007_audit_metadata_sanitize.sql ==========
-- TOFFY AI YouTube Studio — ปิด M2: sanitize audit metadata ที่ระดับ DB
--
-- เดิม sanitize อยู่แค่ฝั่ง TS (lib/audit/sanitize.ts) → ถ้าเรียก log_audit RPC ตรง
-- (ข้าม TS wrapper) จะเก็บ secret/PII ดิบได้ (ละเมิด NFR-009 เชิง defense-in-depth)
-- แก้: sanitize ที่ DB ใน log_audit เอง — deny-list ชุดเดียวกับฝั่ง TS + ปิด gap L1
-- (signing_key, session_id ที่ heuristic TS พลาด) + mask email
--
-- ขอบเขต: strip top-level + recurse เข้า nested object (ครอบมากกว่า TS ปัจจุบัน)
-- ไม่แตะ 0006 (immutable แล้ว) · signature log_audit คงเดิมเป๊ะเพื่อรักษา grant/revoke

set search_path = public;

-- pure transform: strip key อ่อนไหว (case-insensitive) + mask email ; recurse nested object
create or replace function public.sanitize_audit_metadata(input jsonb)
returns jsonb
language plpgsql
immutable
security definer
set search_path = ''
as $$
declare
  result jsonb := '{}'::jsonb;
  k text;
  v jsonb;
  lk text;
  is_sensitive boolean;
  s text;
  email_txt text;
  masked text;
  -- ให้สอดคล้องกับ lib/audit/sanitize.ts + ปิด gap ที่ audit L1 ชี้ (signing_key, session_id)
  substr_sensitive text[] := array[
    'password','passwd','token','secret','apikey','api_key','authorization',
    'cookie','jwt','credential','private_key','access_key','signing_key','session_id'
  ];
  exact_sensitive text[] := array['key','pass','auth','pwd'];
begin
  if input is null or jsonb_typeof(input) <> 'object' then
    return '{}'::jsonb;   -- ไม่ throw กับ input ว่าง/ผิด shape
  end if;

  for k, v in select key, value from jsonb_each(input)
  loop
    lk := lower(k);

    is_sensitive := (lk = any(exact_sensitive));
    if not is_sensitive then
      foreach s in array substr_sensitive loop
        if position(s in lk) > 0 then
          is_sensitive := true;
          exit;
        end if;
      end loop;
    end if;

    if is_sensitive then
      continue;  -- ตัดทิ้ง
    elsif jsonb_typeof(v) = 'object' then
      -- recurse เข้า nested object
      result := result || jsonb_build_object(k, public.sanitize_audit_metadata(v));
    elsif position('email' in lk) > 0 and jsonb_typeof(v) = 'string' then
      -- mask email: เก็บตัวแรก + โดเมน (a***@b.com)
      email_txt := v #>> '{}';
      if position('@' in email_txt) > 1 then
        masked := left(email_txt, 1) || '***@' || split_part(email_txt, '@', 2);
      else
        masked := '***';
      end if;
      result := result || jsonb_build_object(k, to_jsonb(masked));
    else
      result := result || jsonb_build_object(k, v);
    end if;
  end loop;

  return result;
end $$;

-- แก้ log_audit ให้ sanitize ที่ DB ก่อน insert (signature เดิมเป๊ะ → grant/revoke จาก 0005 คงอยู่)
create or replace function public.log_audit(
  p_action text,
  p_entity_type text default null,
  p_entity_id uuid default null,
  p_workspace_id uuid default null,
  p_result audit_result default 'success',
  p_metadata jsonb default '{}'::jsonb
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.audit_logs
    (workspace_id, actor_user_id, action, entity_type, entity_id, result, metadata)
  values
    (p_workspace_id, auth.uid(), p_action, p_entity_type, p_entity_id, p_result,
     public.sanitize_audit_metadata(coalesce(p_metadata, '{}'::jsonb)));
end $$;


-- ========== 0008_channel_insert_gate.sql ==========
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


-- ========== 0009_episode_transition.sql ==========
-- TOFFY AI YouTube Studio — FR-010: ควบคุม State Transition ของ episode
--
-- ปัญหาเดิม: episodes_write (0003) เป็น FOR ALL → owner/editor ยิง
-- UPDATE episodes SET status='published' ตรงได้ ข้ามทุกกฎ transition
-- (บทเรียนเดียวกับ M1/M-new ที่ channels)
--
-- แก้ (defense in depth):
--  1) episode_transition_allowed(from,to): allowed-map = source of truth ที่ DB
--  2) episodes_status_guard (BEFORE UPDATE): บล็อกเปลี่ยน status ตรง เว้นมี GUC flag
--     (reuse flag app.allow_status_change เดียวกับ channel — คุม channel+episode ทางเดียว)
--  3) transition_episode(id,to) RPC: has_channel_write + validate + set flag + log audit (NFR-004)
--
-- immutable: ไม่แตะ 0001–0008 → เพิ่มด้วยไฟล์ใหม่ 0009
-- seed_puifun ไม่กระทบ: insert episode status ตรง (INSERT ไม่ใช่ UPDATE) trigger BEFORE UPDATE ไม่ยิง

set search_path = public;

-- ── (1) allowed-transition map (มี back-edge + {any}→archived) ─────────
create or replace function public.episode_transition_allowed(
  p_from public.episode_status,
  p_to public.episode_status
) returns boolean language sql immutable set search_path = '' as $$
  select
    -- เก็บเข้ากรุได้จากทุกสถานะที่ยังไม่ archived
    (p_from <> 'archived' and p_to = 'archived')
    or (p_from, p_to) in (
      ('draft','scripted'),
      ('scripted','in_production'),
      ('in_production','qc'), ('in_production','scripted'),
      ('qc','ready'), ('qc','in_production'), ('qc','scripted'),
      ('ready','published'), ('ready','qc')
    );
$$;

-- ── (2) guard: เปลี่ยน status ตรงไม่ได้ (ต้องผ่าน transition_episode) ──
create or replace function public.episodes_guard_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status is distinct from old.status
     and coalesce(current_setting('app.allow_status_change', true), '') <> '1' then
    raise exception 'เปลี่ยนสถานะ episode ต้องผ่าน transition_episode (FR-010) — เปลี่ยนตรงไม่ได้';
  end if;
  return new;
end $$;

drop trigger if exists episodes_status_guard on episodes;
create trigger episodes_status_guard
  before update on episodes
  for each row execute function public.episodes_guard_status();

-- ── (3) RPC transition_episode: จุดเดียวที่เปลี่ยน status ได้ ──────────
create or replace function public.transition_episode(
  p_id uuid,
  p_to public.episode_status
) returns public.episodes language plpgsql security definer set search_path = '' as $$
declare
  e    public.episodes;
  v_ch uuid;
  v_ws uuid;
  v_old public.episode_status;
begin
  select * into e from public.episodes where id = p_id;
  if e.id is null then
    raise exception 'ไม่พบ episode';   -- RLS: ไม่ใช่สมาชิกจะมองไม่เห็น → ตกที่นี่
  end if;
  v_ch  := e.channel_id;
  v_old := e.status;

  -- สิทธิ์เขียน (owner+editor ของช่อง)
  if not public.has_channel_write(v_ch) then
    raise exception 'ไม่มีสิทธิ์เปลี่ยนสถานะ episode (ต้องเป็น owner/editor ของช่อง)';
  end if;

  -- validate transition (ปฏิเสธ invalid ฝั่ง server — FR-010)
  if not public.episode_transition_allowed(v_old, p_to) then
    raise exception 'invalid transition: % → %', v_old, p_to;
  end if;

  -- อนุญาตเปลี่ยน status เฉพาะใน tx นี้ แล้ว update
  perform set_config('app.allow_status_change', '1', true);
  update public.episodes set status = p_to where id = p_id returning * into e;

  -- audit (NFR-004) — ผูก workspace เพื่อ scope
  select workspace_id into v_ws from public.channels where id = v_ch;
  perform public.log_audit(
    'episode.transition', 'episode', p_id, v_ws,
    'success'::public.audit_result,
    jsonb_build_object('from', v_old, 'to', p_to)
  );

  return e;
end $$;

-- ── สิทธิ์: Postgres grant EXECUTE ให้ PUBLIC โดย default → revoke ก่อน ─
revoke execute on function public.episode_transition_allowed(public.episode_status, public.episode_status) from public;
revoke execute on function public.transition_episode(uuid, public.episode_status) from public;
grant execute on function public.episode_transition_allowed(public.episode_status, public.episode_status) to authenticated;
grant execute on function public.transition_episode(uuid, public.episode_status) to authenticated;


-- ========== 0010_assets_rights.sql ==========
-- TOFFY AI YouTube Studio — FR-009: Asset provenance + Rights (ADR-003)
--
-- assets / rights_records มีอยู่แล้วตั้งแต่ 0001 (rename rights_log→rights_records ใน 0003)
-- RLS เปิดไว้แต่ deny-all → migration นี้ (1) เติมคอลัมน์ provenance (2) เปิด policy ใช้งานจริง
-- (3) บังคับ 1:1 asset↔rights ด้วย UNIQUE + RPC atomic create
--
-- immutable: ไม่แตะ 0001–0009 · ทั้งสองตารางว่าง (ไม่มี seed) → เพิ่ม NOT NULL ปลอดภัย
-- read helper ชื่อจริง = can_access_channel (ไม่มี has_channel_read) · write = has_channel_write
-- character_id = ตัดออกรอบนี้ (หนี้ L) · ยังไม่ทำ file upload/storage (storage_path เก็บ path/URL)

set search_path = public;

-- ── enum บทบาทของ asset ─────────────────────────────────────────────
do $$ begin
  create type asset_role as enum ('anchor', 'scene', 'song', 'sfx', 'narration');
exception when duplicate_object then null; end $$;

-- ── (1) เติมคอลัมน์ provenance ───────────────────────────────────────
alter table assets add column if not exists channel_id uuid
  references channels(id) on delete cascade;
alter table assets add column if not exists role asset_role;
alter table assets add column if not exists title text;
alter table assets add column if not exists created_by uuid references auth.users(id);
-- ว่าง → set NOT NULL ได้เลย (asset ต้องผูก channel เสมอ — channel-scoped)
alter table assets alter column channel_id set not null;
create index if not exists assets_channel_idx on assets(channel_id);

alter table rights_records add column if not exists plan text;
alter table rights_records add column if not exists model text;
alter table rights_records add column if not exists source_url text;
alter table rights_records add column if not exists created_by uuid references auth.users(id);
alter table rights_records add column if not exists exported_at timestamptz not null default now();
-- 1:1 asset↔rights (ADR-003)
alter table rights_records drop constraint if exists rights_records_asset_id_key;
alter table rights_records add constraint rights_records_asset_id_key unique (asset_id);

-- ── (2) เปิด RLS policy (deny-all → channel-scoped) ──────────────────
-- assets: channel-scoped ตรงผ่าน channel_id
create policy assets_select on assets for select to authenticated
  using (public.can_access_channel(channel_id));
create policy assets_insert on assets for insert to authenticated
  with check (public.has_channel_write(channel_id));
create policy assets_update on assets for update to authenticated
  using (public.has_channel_write(channel_id))
  with check (public.has_channel_write(channel_id));
create policy assets_delete on assets for delete to authenticated
  using (public.has_channel_write(channel_id));

-- rights_records: ผูกผ่าน asset → channel
create policy rr_select on rights_records for select to authenticated
  using (exists (
    select 1 from public.assets a
    where a.id = asset_id and public.can_access_channel(a.channel_id)));
create policy rr_insert on rights_records for insert to authenticated
  with check (exists (
    select 1 from public.assets a
    where a.id = asset_id and public.has_channel_write(a.channel_id)));
create policy rr_update on rights_records for update to authenticated
  using (exists (
    select 1 from public.assets a
    where a.id = asset_id and public.has_channel_write(a.channel_id)))
  with check (exists (
    select 1 from public.assets a
    where a.id = asset_id and public.has_channel_write(a.channel_id)));
create policy rr_delete on rights_records for delete to authenticated
  using (exists (
    select 1 from public.assets a
    where a.id = asset_id and public.has_channel_write(a.channel_id)));

-- ── สิทธิ์ระดับตาราง (0003 ยังไม่ได้ grant assets/rights_records) ─────
grant select, insert, update, delete on assets, rights_records to authenticated;

-- ── (3) RPC atomic: สร้าง asset + rights คู่เดียว (1 asset ต้องมี 1 rights) ─
-- หมายเหตุ: เพิ่มนอกเหนือรายการ ALTER ใน handoff เพื่อรับประกัน 1:1 แบบ atomic
-- (กัน asset กำพร้าเมื่อ insert rights ล้มกลางคัน) — enforcement "rights ห้ามว่าง" ที่ server
create or replace function public.create_asset_with_rights(
  p_channel_id  uuid,
  p_type        public.asset_type,
  p_role        public.asset_role,
  p_title       text,
  p_episode_id  uuid,
  p_storage_path text,
  p_source_tool text,
  p_tool_used   text,
  p_plan        text,
  p_model       text,
  p_prompt_used text,
  p_source_url  text,
  p_license_note text,
  p_exported_at timestamptz
) returns public.assets language plpgsql security definer set search_path = '' as $$
declare a public.assets;
begin
  if not public.has_channel_write(p_channel_id) then
    raise exception 'ไม่มีสิทธิ์สร้าง asset ในช่องนี้ (ต้องเป็น owner/editor)';
  end if;
  -- ถ้าผูก episode ต้องเป็น episode ของ channel เดียวกัน (กัน cross-channel)
  if p_episode_id is not null and not exists (
    select 1 from public.episodes e where e.id = p_episode_id and e.channel_id = p_channel_id
  ) then
    raise exception 'episode ไม่ได้อยู่ในช่องนี้';
  end if;

  insert into public.assets
    (channel_id, episode_id, type, role, title, storage_path, source_tool, created_by)
  values
    (p_channel_id, p_episode_id, p_type, p_role, nullif(btrim(p_title), ''),
     p_storage_path, nullif(btrim(p_source_tool), ''), auth.uid())
  returning * into a;

  insert into public.rights_records
    (asset_id, tool_used, plan, model, prompt_used, source_url, license_note, exported_at, created_by)
  values
    (a.id, p_tool_used, nullif(btrim(p_plan), ''), nullif(btrim(p_model), ''),
     nullif(btrim(p_prompt_used), ''), nullif(btrim(p_source_url), ''),
     nullif(btrim(p_license_note), ''), coalesce(p_exported_at, now()), auth.uid());

  return a;
end $$;

revoke execute on function public.create_asset_with_rights(
  uuid, public.asset_type, public.asset_role, text, uuid, text, text,
  text, text, text, text, text, text, timestamptz) from public;
grant execute on function public.create_asset_with_rights(
  uuid, public.asset_type, public.asset_role, text, uuid, text, text,
  text, text, text, text, text, text, timestamptz) to authenticated;


-- ========== 0011_characters_bible.sql ==========
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


-- ========== 0012_episode_characters.sql ==========
-- TOFFY AI YouTube Studio — episode_characters (m2m join: episode ↔ character)
--
-- ปิดหนี้ character_id: episode มีหลายตัวละคร + ตัวละครอยู่หลายตอน = many-to-many
-- ไม่แตะ episodes/characters (แค่อ้าง FK) · RLS scope ผ่าน episode → channel membership
--
-- ความปลอดภัย:
-- * same-channel: link ข้าม channel (episode ch.A + character ch.B) ต้องบล็อกที่ DB
--   → helper same_channel_writable (SECURITY DEFINER, search_path='') ใน WITH CHECK ของ INSERT
-- * on delete: episode CASCADE (ลบตอน → ลบลิงก์) · character RESTRICT (กันลบตัวละครที่ยังผูก = provenance)
-- * write = write-access ของ episode · ไม่มี UPDATE policy/grant (link เป็น immutable pair)
-- immutable: ไฟล์ใหม่ 0012 · RLS มาพร้อมตาราง (ADR-001)

set search_path = public;

-- ── ตาราง join ─────────────────────────────────────────────────────
create table if not exists episode_characters (
  episode_id   uuid not null references episodes(id)   on delete cascade,
  character_id uuid not null references characters(id) on delete restrict,
  created_at   timestamptz not null default now(),
  primary key (episode_id, character_id)
);
-- reverse lookup (character → episodes) + ทำ RESTRICT เร็ว
create index if not exists episode_characters_character_idx on episode_characters(character_id);

alter table episode_characters enable row level security;

-- ── helper: บังคับ same-channel + write ที่ DB (qualify เต็ม, search_path='') ──
create or replace function public.same_channel_writable(p_ep uuid, p_char uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.episodes e
    join public.characters c on c.id = p_char
    where e.id = p_ep
      and e.channel_id = c.channel_id
      and public.has_channel_write(e.channel_id)
  );
$$;
revoke execute on function public.same_channel_writable(uuid, uuid) from public;
grant  execute on function public.same_channel_writable(uuid, uuid) to authenticated;

-- ── RLS policy (แยกต่อ command · ไม่มี UPDATE = deny-by-default) ──────
-- SELECT: เป็น member ของ channel ที่ episode สังกัด
create policy ec_select on episode_characters for select to authenticated
  using ( public.can_access_channel(
            (select channel_id from public.episodes where id = episode_id)) );

-- INSERT: same-channel + write-access (helper) → cross-channel ถูกบล็อก
create policy ec_insert on episode_characters for insert to authenticated
  with check ( public.same_channel_writable(episode_id, character_id) );

-- DELETE: write-access ของ episode พอ (เคลียร์ลิงก์ได้เสมอ ไม่มี row cross-channel ค้าง)
create policy ec_delete on episode_characters for delete to authenticated
  using ( public.has_channel_write(
            (select channel_id from public.episodes where id = episode_id)) );

-- สิทธิ์ระดับตาราง: ไม่ให้ update / ไม่ให้ anon
grant select, insert, delete on episode_characters to authenticated;

