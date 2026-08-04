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
