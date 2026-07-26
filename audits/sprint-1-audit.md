# Sprint 1 — Audit Report (Principal Architect / Security Reviewer)

- ขอบเขต: Task 1.1 (Auth) · 1.2 (workspaces + RLS) · 1.3 (channels + Gate 0) · 1.4 (audit log)
- Head ที่ตรวจ: `3717549` (branch `claude/toffy-collaboration-system-wnnlpv`)
- วันที่: 25 ก.ค. 2026
- เกณฑ์ผ่าน: **Critical = 0 และ High = 0**

> หมายเหตุความเป็นกลาง: รอบตรวจนี้ทำใน session เดียวกับผู้พัฒนา (ไม่ใช่ session แยกตามอุดมคติของ Playbook)
> — ควรมี reviewer อิสระยืนยันซ้ำ แต่รายงานนี้ตรวจโดยยึด CLAUDE.md → Security & Audit เป็นเกณฑ์และหา defect ตรง ๆ

## Executive Summary
- ผ่าน VERIFY จริง: `lint` / `typecheck` / `test 43/43` / `build` เขียว + SQL harness 3 ชุด (workspaces / channels+Gate0 / audit+append-only) ผ่าน + `git diff` ไม่มี secret
- RLS multi-tenancy, Gate 0, append-only, revoke-anon-execute ทำได้จริงและมี test พิสูจน์ระดับ DB
- **พบ 1 High** ที่ทำให้ยังไม่ผ่านเกณฑ์: append-only trigger ปะทะกับ FK cascade → ลบ workspace ไม่ได้ (พิสูจน์ซ้ำได้)
- Medium 3 · Low 4 · Test gaps 3 (รวมงาน E2E ที่ยัง blocked)

## นับผล
- **Critical = 0**
- **High = 1**  → ยังไม่ผ่านเกณฑ์ (ต้องเคลียร์ H1 ก่อนขึ้น Episodes UI)
- Medium = 3 · Low = 4

---

## Findings

### [H1] Critical? → **High** · append-only trigger บล็อก cascade → ลบ workspace/user ไม่ได้
- **Evidence:** `supabase/migrations/0005_audit_logs.sql:18-19` (FK `workspace_id ... on delete cascade`, `actor_user_id ... on delete set null`) + trigger `audit_logs_no_update` / `audit_logs_no_delete`
- **Scenario (พิสูจน์แล้ว):** สร้าง workspace → มี audit log 1 แถว → `DELETE FROM workspaces WHERE id=...`
  → cascade `DELETE FROM audit_logs` → trigger `audit_logs_no_delete` RAISE → **ลบ workspace ไม่สำเร็จ**
  ```
  ERROR: audit_logs เป็น append-only — แก้ไข/ลบไม่ได้
  SQL statement "DELETE FROM ONLY public.audit_logs WHERE $1 = workspace_id"
  ```
  เช่นเดียวกัน การลบ user ที่เป็น actor → `on delete set null` → UPDATE audit_logs → trigger `audit_logs_no_update` RAISE
  (ในรีโปปัจจุบันถูกบล็อกก่อนด้วย `workspaces_created_by_fkey` RESTRICT แต่ยังเป็นความเสี่ยงเชิงออกแบบ)
- **Expected vs Actual:** ควรลบ workspace (owner) ได้ / จริง = error เสมอเมื่อมี audit log (workspace.create log ทุกครั้ง → แทบทุก workspace)
- **Impact:** ลบ workspace ไม่ได้เลยในทางปฏิบัติ + ขัดหลัก append-only เอง (cascade จะไป "ลบ" audit ซึ่งไม่ควรลบ)
- **Root cause:** audit_logs ผูก FK แบบ cascade/set-null กับ entity ที่ mutable ขณะเดียวกันบังคับ append-only
- **Recommendation:** ให้ audit_logs เก็บ `workspace_id` / `actor_user_id` เป็น uuid **โดยไม่มี FK referential action** (หรือ FK `on delete no action` ที่ไม่ไปแตะ audit_logs) — audit ควรเก็บ id ประวัติไว้แม้ entity ถูกลบ (เป็นแนวปฏิบัติมาตรฐานของตาราง audit)
- **Test to add:** harness เคส "ลบ workspace ที่มี audit log สำเร็จ + audit row ยังอยู่ (id ค้างเป็นประวัติ)"
- **Rollback/Risk:** แก้เป็น migration 0006 (drop constraint + re-add แบบไม่มี action) — ปลอดภัย ยังไม่ deploy

### [M1] channel approval ทำผ่าน UPDATE ตรงได้ → ข้าม approve_channel + ไม่มี audit
- **Evidence:** `supabase/migrations/0003_channels.sql:149` `channels_update` policy อนุญาต owner แก้ทุกฟิลด์รวม `status`
- **Scenario:** owner ยิง `UPDATE channels SET status='approved'` ตรง → อนุมัติได้โดยไม่ผ่าน `approve_channel` RPC → ไม่มี `channel.approve` audit log
- **Impact:** NFR-004 (approval ต้องถูก audit) มีช่องหลุด; การเปลี่ยนสถานะ gate ไม่ถูกควบคุมผ่าน path เดียว
- **Recommendation:** ใน `channels_update` เพิ่ม `with check (status = (select status from channels ...))` เพื่อกันแก้ status ตรง ๆ แล้วบังคับให้เปลี่ยนสถานะผ่าน RPC เท่านั้น (หรือ trigger บันทึก audit เมื่อ status เปลี่ยน)

### [M2] log_audit RPC ไม่ sanitize metadata ที่ระดับ DB → authenticated ยัด secret/PII ได้
- **Evidence:** `supabase/migrations/0005_audit_logs.sql:65-69` insert `p_metadata` ตรง ๆ; sanitize อยู่แค่ฝั่ง TS (`lib/audit/log.ts`)
- **Scenario:** authenticated เรียก `rpc('log_audit',{p_metadata:{password:'x', email:'a@b.com'}})` ตรง → เก็บดิบใน audit_logs
- **Impact:** NFR-009 (ห้าม secret/PII ใน log) พึ่ง client-side อย่างเดียว — โค้ดเราปลอดภัย แต่ defense-in-depth ยังไม่ครบ
- **Recommendation:** เพิ่มการ strip key อ่อนไหว/จำกัด shape ของ metadata ใน RPC (เช่น whitelist keys หรือ jsonb strip) หรือจำกัดว่า metadata เก็บได้เฉพาะ key ที่กำหนด

### [M3] login-failure เขียน audit ผ่าน service-role ทุกครั้งที่ล็อกอินผิด (endpoint สาธารณะ)
- **Evidence:** `lib/auth/actions.ts:20-33,52` `recordLoginFailure` → admin insert ทุก fail
- **Scenario:** โจมตี brute-force หน้า login → แต่ละ fail = 1 แถว audit_logs ผ่าน service-role → โตไม่จำกัด (แม้ anon เขียน RPC ตรงไม่ได้ แต่ทำให้เกิด write ทางอ้อมได้)
- **Impact:** flood/DoS ต่อ storage ของ audit_logs
- **สถานะ:** rate-limit อยู่นอกขอบเขต Sprint 1 (ระบุไว้ชัด) — บันทึกเป็นหนี้ที่ต้องปิดก่อน production
- **Recommendation:** ใส่ rate-limit ต่อ IP/บัญชี + อาจ dedupe/aggregate login-failure ในเฟส NFR

### [L1] sanitizeMetadata เป็น heuristic — พลาดบาง key + ไม่ recurse nested
- **Evidence:** `lib/audit/sanitize.ts` (deny-list `SUBSTRING_SENSITIVE`/`EXACT_SENSITIVE`) — เช่น `signing_key`, `session_id`, object ซ้อน ไม่ถูกตัด
- **Recommendation:** ใช้ whitelist แทน blacklist สำหรับ metadata ที่เก็บได้ + recurse ถ้าจำเป็น

### [L2] assets / rights_records เปิด RLS แบบ deny-all แต่ไม่มี test ครอบ
- **Evidence:** `0003_channels.sql` `alter table assets/rights_records enable row level security;` (ไม่มี policy)
- **Recommendation:** เพิ่ม harness ยืนยัน "authenticated SELECT assets/rights_records = 0 แถว" + วางแผน policy จริงเฟสถัดไป

### [L3] workspace_members ลบ owner คนสุดท้าย/ลดสิทธิ์ตัวเองได้ → workspace ไร้ owner
- **Evidence:** `0002_workspaces.sql` `members_delete`/`members_update` (owner ทำได้ทั้งหมด ไม่มี guard คน owner สุดท้าย)
- **Recommendation:** guard ห้ามลบ/ลดสิทธิ์ owner คนสุดท้าย (raise ถ้า owner_count = 1)

### [L4] episodes มี policy ซ้อน (FOR ALL + FOR SELECT) — ความชัดเจน
- **Evidence:** `0003_channels.sql` `episodes_select` + `episodes_write (for all)` — ทำงานถูก (permissive OR) แต่ซ้ำซ้อน
- **Recommendation:** แยก write เป็น insert/update/delete ให้ชัด หรือคอมเมนต์อธิบายการ OR

---

## Test Gap
- **TG1:** ไม่มี test แยกบทบาท — viewer อ่าน pillars/characters/episodes ได้แต่เขียนไม่ได้ / editor เขียนได้ (`has_channel_write` vs `can_access_channel` ยังไม่ถูกทดสอบ) → ถ้า logic เพี้ยน test จับไม่ได้
- **TG2:** ไม่มี test การเปลี่ยนสถานะ channel (un-approve) และผลต่อ Gate 0
- **TG3 (E2E ยัง blocked):** ต้องรันบน Supabase จริงถึงจะ verify ได้ — auth flow (signInWithPassword/getUser/cookie), `seed_puifun()` ผ่าน JWT จริง, cross-tenant ผ่าน REST 2 บัญชี, login-failure insert ด้วย service-role key จริง

## สิ่งที่ verify ไม่ได้จนกว่าจะรัน E2E
- การล็อกอิน/ออกจากระบบ/สมัคร end-to-end บนเบราว์เซอร์ (harness จำลอง auth.uid() ด้วย GUC เท่านั้น)
- พฤติกรรม `@supabase/ssr` cookie/session จริง + middleware redirect
- seed_puifun ผ่านสิทธิ์ผู้ใช้จริง + RLS ในบริบท JWT ของ Supabase

---

## คำตัดสิน: **Conditional Go**
- ต้องแก้ **H1** ให้เสร็จ (Critical=0/High=0) ก่อนขึ้น Episodes UI
- แนะนำเก็บ M1 (audit ของ approval) ไปพร้อมกัน เพราะกระทบ NFR-004 โดยตรง
- M2/M3/L* บันทึกเป็นหนี้ มีแผนปิดก่อน production ได้
