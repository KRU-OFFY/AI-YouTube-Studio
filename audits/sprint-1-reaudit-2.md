# Sprint 1 — Re-audit #2 (หลังปิด M-new ด้วย migration 0008)

- Head ที่ตรวจ: `6f5bebb` + migration `0008_channel_insert_gate.sql` (commit นี้)
- ไฟล์นี้เป็นบันทึกรอบ re-audit #2 — **ไม่ทับ** `audits/sprint-1-audit.md` (รอบ 1) และ `audits/sprint-1-reaudit.md` (รอบ re-audit หลัง M2)
- ⚠️ **ข้อจำกัดความเป็นอิสระ:** รอบนี้รัน probe เองในเซสชันผู้พัฒนา (ผู้ตรวจอิสระ sub-agent ยังชน platform session limit เหมือนรอบก่อน) — แนะนำให้ผู้ตรวจอิสระยืนยันซ้ำเมื่อ limit reset

## Scope รอบนี้
ปิด **M-new** (Gate 0 INSERT-bypass, Medium) ที่ค้างจาก `audits/sprint-1-reaudit.md` — เป็น finding เดียวที่เหลือในระดับ Medium ที่กระทบ Gate 0

## VERIFY ที่รันจริง (head นี้)
- `npm run lint` / `typecheck` / `test 43/43` / `build` → เขียวทั้งหมด (unit test ไม่ถอยจาก 43)
- SQL harness (Postgres 16 จริง, user pgtest): `_supabase_shim.sql` → `0001..0008` → `rls_workspaces` / `rls_channels` / `rls_audit` → **ผ่านทั้ง 3 ชุด**
- `git diff` ไม่มี secret

## หลักฐานปิด M-new (probe จริง)
migration `0008` เพิ่ม trigger `channels_insert_status_guard` (BEFORE INSERT on channels) — บังคับ channel เกิดใหม่ต้อง `status='draft'` เว้นแต่มี GUC `app.allow_status_change='1'` (reuse flag เดียวกับ M1 → คุม INSERT + UPDATE ทางเดียวกัน)

| Probe | ผล | สรุป |
|---|---|---|
| owner `INSERT channels(...,status='approved')` ตรง | **BLOCKED** — `สร้าง channel ต้องเป็น draft — อนุมัติผ่าน approve_channel เท่านั้น (Gate 0)` | ✅ ปิด M-new |
| owner `INSERT channels(...)` ปกติ (ไม่ส่ง status) | `status=draft` | ✅ regression (createChannel ไม่พัง) |
| `approve_channel(ch)` หลัง insert draft | `status=approved` | ✅ regression (UPDATE path ยังทำงาน) |
| `seed_puifun()` (ผ่าน RPC) | channel 'ปุยฝัน' = approved · forbidden_words=11 · episodes=10 | ✅ seed ไม่พัง (ตั้ง flag ก่อน INSERT) |

หมายเหตุ evidence file:line
- `supabase/migrations/0008_channel_insert_gate.sql:17` — trigger function `channels_guard_insert_status`
- `supabase/migrations/0008_channel_insert_gate.sql:29` — `create trigger ... before insert on channels`
- `supabase/migrations/0008_channel_insert_gate.sql:53` — `set_config('app.allow_status_change','1',true)` ก่อน INSERT channels ใน seed_puifun (create or replace)
- `supabase/tests/rls_channels_test.sql` — เพิ่ม 3 assertion: INSERT approved → blocked · insert ปกติ → draft · seed_puifun ผ่าน

## ยืนยันฟิกซ์เดิมไม่ regress (harness รอบนี้ครอบ)
- **H1** ลบ workspace ที่มี audit row → สำเร็จ + audit row คงอยู่ (append-only แท้)
- **M1** UPDATE channels.status ตรง → BLOCKED · approve_channel → approved
- **M2** log_audit ตรง → strip sensitive + email masked + nested ปลอดภัย (DB-level)
- **anon** เรียก log_audit ไม่ได้ · anon SELECT audit_logs = 0

## Findings

### CRITICAL = 0 · HIGH = 0 · MEDIUM = 1 (M3 หนี้ที่หัวหน้ารับ)

- **[M-new] ✅ ปิดแล้ว** (rebadged จาก Medium → CLOSED) — หลักฐานตารางด้านบน
- **[M3] login-failure ไม่มี rate-limit** — ยังเปิด (หนี้ที่หัวหน้ารับไว้; `lib/auth/actions.ts` `recordLoginFailure` insert ทุก fail ผ่าน service-role)

### LOW (หนี้เดิม — ไม่ทำรอบนี้)
- **L1** `lib/audit/sanitize.ts` (TS) ยัง blacklist + ไม่ recurse (ฝั่ง DB 0007 recurse ครบแล้ว)
- **L2** assets/rights_records deny-all ไม่มี harness ยืนยัน
- **L3** ไม่มี guard "owner คนสุดท้าย" ใน workspace_members
- **L4** episodes policy ซ้อน FOR ALL + FOR SELECT (ถูกแต่ซ้ำ)

### Test Gap
- **TG1** ไม่มี test แยกบทบาท viewer/editor (`has_channel_write`) — ทำพร้อม Episodes UI
- **TG2** ไม่มี test un-approve/Gate0
- **TG3** E2E บน Supabase จริง (auth/cookie ผ่าน JWT, seed_puifun ผ่าน REST, cross-tenant REST) — ยัง verify ไม่ได้ในเครื่องนี้

## นับผล & คำตัดสิน
- **Critical = 0 · High = 0 · Medium = 1 (M3 หนี้)** · Low = 4 · Test gap = 3
- **Verdict: Go** — Sprint 1 hardening ครบ; Gate 0 ปิดทั้ง INSERT + UPDATE path แล้ว; ขึ้น E2E/Episodes UI ได้
- แนะนำ: ปิด TG3 (E2E บน local Supabase) เป็นด่านถัดไปก่อน Episodes UI (ตาม handoff ที่หัวหน้าเคาะ)
