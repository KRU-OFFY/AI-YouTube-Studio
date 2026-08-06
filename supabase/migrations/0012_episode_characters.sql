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
