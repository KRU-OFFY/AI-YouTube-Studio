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
