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
