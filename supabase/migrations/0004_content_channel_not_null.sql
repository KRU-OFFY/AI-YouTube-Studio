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
