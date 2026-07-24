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
grant execute on function public.create_workspace(text, text, text) to authenticated;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.is_workspace_owner(uuid) to authenticated;
