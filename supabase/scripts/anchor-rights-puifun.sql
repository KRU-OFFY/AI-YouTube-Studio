-- Manual data-load (idempotent) — บันทึก anchor image + rights ของ น้องปุย / มุ่ย
-- ปุยฝัน · FR-009 provenance · metadata เท่านั้น (ไม่แตะ schema/RLS)
--
-- วิธีรัน (บน DB ที่ apply migration 0001..0012 + เรียก seed_puifun แล้ว):
--   psql "<connection>" -f supabase/scripts/anchor-rights-puifun.sql
--   หรือวางใน Supabase SQL editor (รันในสิทธิ์ postgres/superuser)
--
-- กลไก: resolve owner ของ workspace 'Puifun Studio' + channel 'puifun' แล้ว impersonate
-- owner (ตั้ง request.jwt.claims + role authenticated) เพื่อให้ RPC create_asset_with_rights
-- ผ่าน has_channel_write + ตั้ง created_by = owner. idempotent: ข้ามถ้ามี anchor asset ชื่อเดิมแล้ว
--
-- constraint: rights_records.asset_id = NOT NULL + UNIQUE (1:1) → ต้องมี asset ก่อน
--   จึงสร้างเป็น 1 asset (type=image, role=anchor) + 1 rights_records ต่อคาแรกเตอร์

do $seed$
declare
  v_ws    uuid;
  v_owner uuid;
  v_ch    uuid;
  v_note  text := 'ไม่มี seed lock — ใช้ไฟล์ anchor เป็น reference สำหรับฉากในอนาคต (seed: ไม่มี/ไม่รองรับ)';
  p_pui   text := $q$a small round fluffy white puff creature, soft cream-white fur, large round dark brown eyes with single highlight, soft pink cheeks, tiny puff nubs instead of arms, no mouth teeth, pastel storybook illustration, soft rounded edges, gentle lighting, no text, front-facing full body character reference sheet, simple plain pastel background, centered, neutral standing pose$q$;
  p_muui  text := $q$a small gentle hedgehog character, extremely soft rounded puffy quills like tufts of cotton or sheep wool, no pointed tips at all, no spiky texture, light warm brown fluffy round quill clusters, cream face, mint green scarf, kind narrow gentle eyes, pastel storybook illustration, soft rounded edges, no text, front-facing reference sheet, plain pastel background, centered neutral pose$q$;
begin
  -- owner ของ workspace 'Puifun Studio'
  select w.id, m.user_id into v_ws, v_owner
    from public.workspaces w
    join public.workspace_members m on m.workspace_id = w.id and m.role = 'owner'
   where w.name = 'Puifun Studio'
   limit 1;
  if v_owner is null then
    raise exception 'ไม่พบ owner ของ workspace "Puifun Studio" — รัน seed_puifun() ก่อน';
  end if;

  -- channel 'ปุยฝัน'
  select id into v_ch from public.channels where workspace_id = v_ws and slug = 'puifun' limit 1;
  if v_ch is null then
    raise exception 'ไม่พบ channel ปุยฝัน (slug=puifun)';
  end if;

  -- impersonate owner เพื่อให้ RPC เช็ก has_channel_write ผ่าน + created_by = owner
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text)::text, true);
  set local role authenticated;

  -- [น้องปุย] anchor
  if not exists (
    select 1 from public.assets
     where channel_id = v_ch and role = 'anchor' and title = 'Anchor — น้องปุย'
  ) then
    perform public.create_asset_with_rights(
      v_ch, 'image', 'anchor', 'Anchor — น้องปุย',
      null, 'anchor/nong-pui.png', 'ChatGPT (image)',
      'ChatGPT (โหมดสร้างรูปภาพ)', null, null, p_pui,
      null, v_note, '2026-08-08'::timestamptz);
  end if;

  -- [มุ่ย] anchor
  if not exists (
    select 1 from public.assets
     where channel_id = v_ch and role = 'anchor' and title = 'Anchor — มุ่ย'
  ) then
    perform public.create_asset_with_rights(
      v_ch, 'image', 'anchor', 'Anchor — มุ่ย',
      null, 'anchor/muui.png', 'ChatGPT (image)',
      'ChatGPT (โหมดสร้างรูปภาพ)', null, null, p_muui,
      null, v_note, '2026-08-08'::timestamptz);
  end if;

  reset role;
end
$seed$;
