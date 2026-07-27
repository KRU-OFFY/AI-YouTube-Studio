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
