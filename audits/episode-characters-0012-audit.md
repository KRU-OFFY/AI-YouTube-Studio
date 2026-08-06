# Independent Audit — PR #5 `episode_characters` (m2m join, migration 0012)

- **Head commit ที่ตรวจ:** `954aca5` (branch `feat/episode-characters`)
- **วันที่ตรวจ:** 2026-08-06
- **ผู้ตรวจ:** Independent sub-agent (Principal Architect + Security Reviewer) — ไม่ใช่ผู้เขียนโค้ดนี้
- **Scope:** เฉพาะ diff `main...feat/episode-characters` (migration 0012 + test + `lib/episode/actions.ts` link/unlink + `components/EpisodeCharacters.tsx` + `app/(app)/episodes/[id]/page.tsx` + `.circleci/config.yml`)
- **อ้างอิงเดิม (นอก scope, ไม่ออกเป็น finding ใหม่):** 0003 (helper `can_access_channel`/`has_channel_write`, RLS), 0009 (episode state guard), 0011 (characters bible)

---

## 1. Executive Summary

migration 0012 เพิ่มตาราง join `episode_characters` (m2m ระหว่าง episode ↔ character) พร้อม RLS ครบต่อ command และ helper `same_channel_writable` ที่บังคับ same-channel + write ที่ระดับ DB. การตรวจนี้รัน migration ทั้งชุด (0001–0012) + harness ทั้ง 7 ไฟล์บน Postgres 16 จริง และเพิ่ม probe อิสระที่จับ SQLSTATE ดิบ. โมเดลความปลอดภัยแน่นหนา: cross-channel link, viewer write, non-member access, anon access, และ UPDATE ถูกปฏิเสธที่ DB ทุกกรณี (SQLSTATE 42501); provenance ของตัวละครถูกกันด้วย ON DELETE RESTRICT (23503); cascade ทำงานถูก.

พบเพียง **1 Low** (audit-fidelity ของ `unlinkCharacter` บน no-op) + **1 Low/Informational** (ไม่มี state-lock เมื่อ episode = published — เป็น deferral ที่รับได้). **ไม่มี Critical / High / Medium.**

- **Verdict: GO** สำหรับ merge PR #5.

---

## 2. VERIFY — รันจริง (ไม่ใช่เชื่อผลผู้เขียน)

**Environment:** Postgres 16 ชั่วคราว (user `pgtest`, port 55432), ลำดับ shim → 0001..0012 → harness.

### 2.1 Migration + Harness (ผลดิบ)

```
== supabase/migrations/0001_init.sql .. 0012_episode_characters.sql ==   → ALL MIGRATIONS DONE (0012 ถึงจริง)

===== rls_workspaces =====            RLS HARNESS PASSED
===== rls_channels =====              CHANNELS RLS + GATE 0 HARNESS PASSED
===== rls_audit =====                 AUDIT RLS + APPEND-ONLY + H1 DELETE HARNESS PASSED
===== rls_episodes =====              EPISODE STATE-TRANSITION HARNESS PASSED
===== rls_assets =====                ASSET + RIGHTS RLS HARNESS PASSED
===== rls_characters =====            CHARACTERS RLS + BIBLE SEED HARNESS PASSED
===== rls_episode_characters =====    EPISODE_CHARACTERS (m2m) RLS HARNESS PASSED
```

### 2.2 Probe อิสระ (จับ SQLSTATE ดิบ — ยืนยันที่ DB ไม่ใช่ UI)

| Probe | สถานการณ์ | ผลดิบ | คาดหวัง | ผ่าน |
|---|---|---|---|---|
| ก | owner ครอง channel A+B → INSERT (epA, charB) cross-channel | `BLOCKED sqlstate=42501` new row violates RLS | ปฏิเสธที่ DB | ✅ |
| ก2 | owner same-channel INSERT (epA, charA) | INSERT SUCCEEDED | สำเร็จ | ✅ |
| ข | viewer SELECT count | `viewer_sees = 1` | เห็น | ✅ |
| ข2 | viewer INSERT | `BLOCKED sqlstate=42501` | ปฏิเสธ | ✅ |
| ข3 | viewer DELETE | `row_count=0` (USING=false) | 0 แถว | ✅ |
| ค | non-member (คนละ workspace) SELECT | `nonmember_sees = 0` | 0 แถว | ✅ |
| ค | non-member INSERT | `BLOCKED sqlstate=42501` | ปฏิเสธ | ✅ |
| ค | non-member DELETE | `row_count=0` | 0 แถว | ✅ |
| ง | delete character ที่ยังผูก | `RESTRICT sqlstate=23503` FK violation | RESTRICT | ✅ |
| จ | delete episode ที่มี link | join rows = 0 หลังลบ | cascade | ✅ |
| ฉ | UPDATE episode_characters | `denied sqlstate=42501` permission denied | ไม่มี grant → ปฏิเสธ | ✅ |
| ช | anon SELECT | `denied sqlstate=42501` permission denied | ไม่มี grant anon | ✅ |

### 2.3 Node toolchain (รันจริง)

```
npm run lint       → ✔ No ESLint warnings or errors
npm run typecheck  → tsc --noEmit (ไม่มี error)
npm run test       → 7 files / 77 tests passed
npm run build      → สำเร็จ (route /episodes/[id] 2.24 kB compiled)
```

### 2.4 Secret scan + ผลกระทบ episodes

- `git diff main...feat/episode-characters` — **ไม่พบ** สตริงลักษณะ secret/token/service_role/JWT
- 0012 **ไม่ ALTER** `episodes`/`characters` — มีเพียง `alter table episode_characters enable row level security` (เป็นตารางใหม่) + อ้าง FK. Gate 0 / episodes_status_guard (0009) ไม่ถูกแตะ
- `same_channel_writable` มีเฉพาะใน 0012 ไฟล์เดียว — ไม่ชนกับที่อื่น
- actions/component/page ใช้ `createSupabaseServerClient` — **ไม่มี** admin/service-role client (RLS มีผลจริง)
- `log_audit` RPC ตั้ง actor = `auth.uid()` เสมอ (caller ปลอม actor ไม่ได้), metadata ผ่าน `sanitizeMetadata`; metadata ของ link/unlink = `{ character_id: <uuid> }` เท่านั้น (ไม่มี PII/secret)

---

## 3. การตรวจโครงสร้าง 0012 (ตรงเกณฑ์ CLAUDE.md)

| เกณฑ์ | ผล |
|---|---|
| `same_channel_writable` = `sql STABLE SECURITY DEFINER SET search_path=''` | ✅ (บรรทัด 28–29) |
| qualify เต็มทุกชื่อใน fn body (`public.episodes`/`public.characters`/`public.has_channel_write`) | ✅ ไม่มี unqualified หลุด |
| `revoke execute ... from public` + `grant ... authenticated` | ✅ (บรรทัด 39–40) |
| `ec_insert` = WITH CHECK เท่านั้น (same_channel_writable) | ✅ |
| `ec_delete` = USING เท่านั้น (has_channel_write ของ channel ของ episode) | ✅ |
| `ec_select` = USING (can_access_channel) | ✅ |
| **ไม่มี UPDATE policy/grant** (immutable pair) | ✅ grant = select,insert,delete เท่านั้น → UPDATE 42501 |
| ไม่ grant anon | ✅ anon SELECT 42501 |
| PK(episode_id, character_id) | ✅ |
| episode_id → episodes ON DELETE **CASCADE** | ✅ |
| character_id → characters ON DELETE **RESTRICT** | ✅ (provenance) |
| index บน character_id | ✅ `episode_characters_character_idx` |
| CI: migration loop `ls 0*.sql` หยิบ 0012 อัตโนมัติ + harness list เพิ่ม `rls_episode_characters_test.sql` | ✅ |

**หมายเหตุ helper เป็น SECURITY DEFINER:** อ่าน `episodes`/`characters` ข้าม RLS โดยตั้งใจ (แบบเดียวกับ `can_access_channel`) แต่ยังผูกกับ `auth.uid()` ผ่าน `has_channel_write` → ประเมินสิทธิ์ของผู้เรียกจริง ไม่ยกสิทธิ์ข้าม channel. ยืนยันด้วย probe ก (owner ครองทั้ง 2 channel ยัง INSERT cross-channel ไม่ได้).

**Subquery ใน policy `ec_select`/`ec_delete`** (`select channel_id from public.episodes where id = episode_id`) รันในสิทธิ์ผู้เรียก → ถ้ามองไม่เห็น episode คืน NULL → `can_access_channel(NULL)=false` → ซ่อนแถว. สอดคล้อง ไม่มี leak (probe ค non-member เห็น 0).

---

## 4. Findings

### L1 · `unlinkCharacter` เขียน audit แม้ DELETE เป็น no-op (0 แถว) · Severity: Low · Confidence: High
- **Evidence:** `lib/episode/actions.ts:168–189` — `unlinkCharacter` เช็กแค่ `if (!error)` แล้ว `logAudit(... "episode.unlink_character" ...)`. RLS ของ `ec_delete` เมื่อผู้ใช้ไม่มี write จะคืน **0 แถว โดยไม่ error** (ยืนยัน probe ข3/ค: viewer & non-member delete → `row_count=0`, ไม่มี exception).
- **Scenario:** viewer (หรือ member ที่ไม่มี write) เรียก server action `unlinkCharacter` บน episode ที่ตนเห็น → ไม่มีแถวถูกลบจริง แต่ระบบยังบันทึก audit `episode.unlink_character` (พร้อม `character_id`).
- **Expected vs Actual:** ควร log เฉพาะเมื่อมีการถอดจริง ↔ ปัจจุบัน log ทุกครั้งที่ไม่มี error → เกิด audit record ที่ทำให้เข้าใจผิดว่ามีการ unlink.
- **Impact:** audit-fidelity/noise เท่านั้น — ไม่ใช่การรั่วไหลสิทธิ์ (viewer เห็น row ได้อยู่แล้ว, actor = auth.uid() ปลอมไม่ได้). ไม่กระทบ integrity ของสิ่งที่เกิดขึ้นจริงใน DB.
- **Recommendation:** ให้ `.delete()` ใช้ `.select()` หรืออ่าน affected count แล้ว log เฉพาะเมื่อ > 0 แถว (คล้ายที่ harness ใช้ `get diagnostics row_count`). ปรับ `linkCharacter` ไม่ต้อง — insert ที่ถูก RLS บล็อกจะ error (42501) จึงไม่ log อยู่แล้ว.
- **Test to add:** viewer เรียก unlink no-op → assert ไม่มีแถวใหม่ใน `audit_logs` action `episode.unlink_character`.
- **Rollback/Risk:** แก้ฝั่ง action layer เท่านั้น ไม่แตะ schema/RLS — ความเสี่ยงต่ำ.

### L2 · ไม่มี state-lock เมื่อ episode = `published` (relink ตัวละครได้หลังเผยแพร่) · Severity: Low/Informational · Confidence: Medium
- **Evidence:** `ec_insert`/`ec_delete` ใช้แค่ `has_channel_write` ไม่ตรวจ `episodes.status`; มีสถานะ `published` (`lib/episode/validation.ts:13`).
- **Scenario:** หลัง episode ถึง `published`, editor ยังผูก/ถอดตัวละครได้ → provenance ของตอนที่เผยแพร่แล้วเปลี่ยนได้โดยไม่ผ่าน re-approval.
- **Impact:** เป็นความเสี่ยงเชิง provenance ของ publish pipeline ในอนาคต — **แต่ยังไม่มี publish pipeline ในเฟสนี้** และตาราง child อื่น (assets) ก็ยังไม่มี state-lock เช่นกัน จึงสอดคล้องกับ scope ปัจจุบัน.
- **Recommendation:** เมื่อสร้าง publish pipeline ให้เพิ่ม guard (trigger/policy) freeze `episode_characters` เมื่อ episode อยู่สถานะ terminal (`published`). ไม่ใช่ blocker ก่อน merge.

---

## 5. Deferred — ยืนยันว่าเป็นการเลื่อนที่รับได้ (ไม่ใช่ช่องโหว่ก่อน merge)

| รายการ deferred | ประเมิน |
|---|---|
| **state-lock** (freeze link เมื่อ published) | รับได้ — publish pipeline ยังไม่มี, ไม่มี invariant ใดถูกละเมิดในเฟสนี้ (ดู L2) |
| **`appears_in`** (denormalized/reverse view) | รับได้ — reverse lookup ทำได้ผ่าน index `episode_characters_character_idx` อยู่แล้ว, เป็น optimization ไม่ใช่ correctness |
| **E2E test** | รับได้ — DB-level RLS ครอบด้วย harness + probe จริงแล้ว; unit (77) + build ผ่าน |
| **L1–L2 ของ characters** (ระดับรายละเอียด character bible) | รับได้ — นอก scope 0012, ครอบใน 0011 audit (#4 GO) แล้ว |

ทั้งหมดเป็นการเลื่อนเชิง enhancement/coverage-depth ไม่ทิ้งช่องโหว่ด้านสิทธิ์/ข้อมูลรั่วที่ merge ได้ทันที.

---

## 6. นับ Severity

| Severity | จำนวน |
|---|---|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 2 (L1 audit-fidelity, L2 state-lock/informational) |

---

## 7. Verdict

**GO** — merge PR #5 ได้.

RLS/สิทธิ์ครบและถูกบังคับที่ระดับ DB (ยืนยันด้วย SQLSTATE ดิบ ไม่ใช่แค่ UI), ไม่กระทบ episodes/Gate 0/state guard, ไม่มี secret, toolchain (lint/typecheck/77 tests/build) + harness 7 ไฟล์ผ่านจริง. Findings ที่พบเป็น Low ทั้งคู่ (audit-fidelity ของ unlink no-op + state-lock ที่เลื่อนได้) — แนะนำแก้ L1 เป็น follow-up สั้น ๆ แต่ไม่ใช่ blocker.
