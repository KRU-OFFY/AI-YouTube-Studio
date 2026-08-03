# Sprint 1 — Re-audit Report (หลังปิด M2)

- Head ที่ตรวจ: `e6dd1c2` (ตอนนี้ merge เข้า `main` = `914702f` แล้ว)
- ไฟล์นี้เป็นบันทึกรอบ re-audit — **ไม่ทับ** `audits/sprint-1-audit.md` (รอบแรก)
- ⚠️ **ข้อจำกัดความเป็นอิสระ:** sub-agent ผู้ตรวจอิสระที่เปิดไว้ล้มกลางคันเพราะชน platform session limit
  รอบนี้จึงรัน probe เองในเซสชันผู้พัฒนา (ไม่ใช่ผู้ตรวจอิสระ 100%) — แนะนำให้ผู้ตรวจอิสระยืนยันซ้ำเมื่อ limit reset

## VERIFY ที่รันจริง
- `npm run lint` / `typecheck` / `test 43/43` / `build` → เขียวทั้งหมด
- SQL harness (Postgres จริง, shim → 0001..0007 → rls_*): workspaces / channels+M1 / audit+H1+M2 → ผ่านทั้ง 3 ชุด
- seed_puifun ยังทำงาน · `git diff` ไม่มี secret

## ยืนยันฟิกซ์ (หลักฐานจาก probe ที่เขียนเอง)
| Fix | ผล probe | สรุป |
|---|---|---|
| **H1** | `DELETE workspaces` ที่มี audit row → **SUCCEEDED**; audit row เหลือ = 1 | ✅ FIXED (append-only แท้ + ลบ entity ได้) |
| **M1** | `UPDATE channels SET status='approved'` ตรง → **BLOCKED** (trigger); `approve_channel()` → approved | ✅ FIXED (UPDATE path) |
| **M2** | `log_audit(...)` ตรง → stored = `{"name":"ok","email":"a***@b.com","nested":{"keep":"y"}}` | ✅ FIXED (DB-level; password/token/signing_key/session_id/nested.secret ถูกตัด, email masked) |
| **M4/CI** | `.circleci/config.yml`: build-and-check (lint+typecheck+test+build) + db-harness (Postgres) | ✅ FIXED (wiring ถูก; CI จริงยังไม่รันในเครื่องนี้) |
| anon | `has_function_privilege(anon, log_audit, execute)` = **false**; anon SELECT audit = 0 | ✅ ไม่ regress |
| signature | `log_audit(text,text,uuid,uuid,audit_result,jsonb)` เดิมเป๊ะ | ✅ grant/revoke คงอยู่ |

## Findings

### CRITICAL = 0 · HIGH = 0

### MEDIUM

**[M-new] Gate 0 INSERT-bypass — owner สร้าง channel เป็น `status='approved'` ตรงได้ (ยังเปิด)**
- Severity: Medium (owner-only — ไม่ใช่ privilege escalation/cross-tenant)
- Evidence:
  - `supabase/migrations/0003_channels.sql` policy `channels_insert` เช็กแค่ `is_workspace_owner(workspace_id)` ไม่เช็ก `status`
  - `channels_status_guard` (0006) เป็น **BEFORE UPDATE** เท่านั้น — ไม่ครอบ INSERT
  - probe: `INSERT INTO channels(workspace_id,name,slug,status) VALUES(..., 'approved')` → **SUCCEEDED status=approved**
- Impact: อนุมัติ channel ได้โดยข้าม `approve_channel` → ไม่มี audit `channel.approve` (NFR-004) และเป็น Gate 0 bypass ทาง INSERT (คู่กับ M1 คนละ path)
- Fix ที่เสนอ: migration `0008` — trigger `BEFORE INSERT on channels` บังคับ channel เกิดใหม่ `status='draft'`
  (อนุมัติได้ทางเดียวผ่าน `approve_channel`) + test INSERT approved → blocked

**[M3] login-failure ไม่มี rate-limit** (ยังเปิด, หนี้ที่หัวหน้ารับไว้)
- `lib/auth/actions.ts` `recordLoginFailure` insert ทุก fail ผ่าน service-role → flood/DoS ต่อ storage

### LOW (หนี้เดิม)
- **L1** `lib/audit/sanitize.ts` (ฝั่ง TS) ยังเป็น blacklist + ไม่ recurse — *หมายเหตุ:* ฝั่ง DB (0007) recurse + ปิด signing_key/session_id แล้ว แต่ TS ยังตามไม่ครบ
- **L2** assets/rights_records deny-all ไม่มี harness ยืนยัน
- **L3** ไม่มี guard "owner คนสุดท้าย" ใน workspace_members
- **L4** episodes policy ซ้อน FOR ALL + FOR SELECT (ถูกแต่ซ้ำ)

### Test Gap
- **TG1** ไม่มี test แยกบทบาท viewer/editor (`has_channel_write`) — ควรทำพร้อม Episodes UI
- **TG2** ไม่มี test un-approve/Gate0
- **TG3** E2E บน Supabase จริง (auth/cookie, seed_puifun ผ่าน JWT, cross-tenant REST, CI จริง) — ยัง verify ไม่ได้

## นับผล & คำตัดสิน
- **Critical = 0 · High = 0** → **ผ่านเกณฑ์** ✅
- Medium = 2 (M-new, M3) · Low = 4 · Test gap = 3
- **Verdict: Go** — Sprint 1 ผ่าน; ขึ้น Episodes UI ได้
- แนะนำปิด **M-new** (Medium, Gate 0) เป็น migration 0008 คู่กับ Episodes เพราะเป็นรูเดียวกับ M1 คนละ path
