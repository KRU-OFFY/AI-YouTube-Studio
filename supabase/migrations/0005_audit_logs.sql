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
