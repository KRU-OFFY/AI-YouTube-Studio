# Audit — PR #4 · Characters / Character Bible (migration 0011)

- **Head commit ที่ตรวจ:** `6de0c2c` (branch `feat/characters`)
- **Base เปรียบเทียบ:** `main` (`git diff main...feat/characters`)
- **วันที่:** 2026-08-06
- **ผู้ตรวจ:** Independent sub-agent (Principal Architect + Security Reviewer) — ไม่ใช่ผู้เขียนโค้ดนี้ · ไม่แก้โค้ด production
- **Scope:** characters / 0011 เท่านั้น (ไฟล์ในตาราง diff ด้านล่าง) — ไม่ตรวจทั้ง repo

## ไฟล์ใน scope (12 ไฟล์, +853/-3)
migration `0011_characters_bible.sql`, test `rls_characters_test.sql`, `lib/character/{validation.ts, validation.test.ts, actions.ts}`, `components/CharacterForms.tsx`, `app/(app)/channels/[id]/characters/page.tsx`, `app/(app)/characters/[id]/page.tsx`, `lib/supabase/middleware.ts`, `.circleci/config.yml`, `PROGRESS.md`, `app/(app)/channels/[id]/page.tsx`

---

## ผล VERIFY (รันจริงทั้งหมด)

### 1) SQL harness (Postgres 16 ชั่วคราว, user `pgtest`)
คำสั่ง: shim → migrations `0001..0011` → test suites 6 ชุด

```
=== MIGRATIONS === 0001..0011 ใช้ได้หมด ไม่มี error/exception
=== TEST SUITES ===
rls_workspaces  → RLS HARNESS PASSED
rls_channels    → CHANNELS RLS + GATE 0 HARNESS PASSED
rls_audit       → AUDIT RLS + APPEND-ONLY + H1 DELETE HARNESS PASSED
rls_episodes    → EPISODE STATE-TRANSITION HARNESS PASSED
rls_assets      → ASSET + RIGHTS RLS HARNESS PASSED
rls_characters  → CHARACTERS RLS + BIBLE SEED HARNESS PASSED
```
ผล: **6/6 PASS**

### 2) Probe อิสระ (เขียนเอง บน DB สะอาดแยกอีกชุด `probedb`)
```
PROBE 1 (as A) seed count      → total=4 · chars=3 · motifs=1
              slug/type        → dao-duang-noi=brand_motif · kaptan-goh/muui/nong-pui=character   ✓
PROBE 2  (B non-member) SELECT → b_sees = 0 แถว                                                   ✓
PROBE 2b (B) INSERT ch A       → ERROR: new row violates row-level security policy                ✓
PROBE 3  (B) UPDATE row A      → name ไม่เปลี่ยน (ยัง 'น้องปุย')                                   ✓
PROBE 4  (viewer C) SELECT     → viewer_sees = 1                                                  ✓
PROBE 5  (viewer C) UPDATE     → 0 rows · name ไม่เปลี่ยน                                          ✓
PROBE 6  (viewer C) INSERT     → ERROR: new row violates row-level security policy                ✓
enum นอก set (villain) INSERT  → ERROR (invalid input value for enum character_type)              ✓
appears_in                     → dao-duang-noi={P1} · kaptan-goh={P2,P3} (ไม่มี P1) · nong-pui/muui={P1,P2,P3}  ✓
seed_puifun grants (proacl)    → {pgtest=X, authenticated=X}  (ไม่มี PUBLIC)  → grant เดิมคงอยู่หลัง create-or-replace  ✓
seed_puifun prosecdef/proconfig→ SECURITY DEFINER=t · search_path=''                              ✓
```
ผลตรง docs/05 §5 ทุกจุด (ชื่อ 4 ตัว · species · brand_motif · กฎ appears_in "กัปตันโก๊ะ ห้าม P1")

### 3) Toolchain
```
npm run lint       → ✔ No ESLint warnings or errors
npm run typecheck  → tsc --noEmit ผ่าน (ไม่มี error)
npm run test       → 7 files · 77 tests PASSED (character 14 tests)
npm run build      → สำเร็จ · route /channels/[id]/characters + /characters/[id] ติด
```

### 4) Secret scan
`git diff main...feat/characters | grep -iE "password|secret|api_key|service_role|token|PRIVATE|eyJ"` → **ไม่พบ** · seed มีแต่ image prompt/สี/บุคลิก ไม่มี PII/secret

---

## Findings

> Critical = 0 · High = 0 · Medium = 0 · Low = 4

### L1 · `created_by` column ถูกเพิ่มแต่ไม่เคยถูกเซ็ต (dead provenance)
- **Severity:** Low · **Evidence:** `supabase/migrations/0011_characters_bible.sql:27`, `lib/character/actions.ts:66-82` (createCharacter ไม่ set created_by), seed_puifun ก็ไม่เซ็ต
- **Scenario:** สร้างตัวละครผ่าน UI หรือ seed → `created_by` เป็น NULL เสมอ
- **Expected vs Actual:** คาดว่าคอลัมน์ provenance ควรบันทึกผู้สร้าง / Actual คอลัมน์มีอยู่แต่ NULL ทุกแถว → ไร้ประโยชน์ในเชิง provenance · อีกทั้ง FK `references auth.users(id)` ไม่ระบุ `on delete` (ต่างจาก `channels.created_by ... on delete set null` ใน 0003)
- **Recommendation:** ถ้าจะใช้ ให้ set `created_by: user.id` ใน createCharacter (และ seed ใช้ `v_uid`) + เพิ่ม `on delete set null`; ถ้ายังไม่ใช้ ให้ตัดคอลัมน์ออกในไฟล์ migration ถัดไปเพื่อลด dead schema
- **Test to add:** unit/integration ยืนยัน created_by = ผู้เรียกหลัง insert

### L2 · Test enum/insert ใช้ `exception when others` กว้างเกิน (อาจ pass ลอย)
- **Severity:** Low · **Evidence:** `supabase/tests/rls_characters_test.sql:51` (`when invalid_text_representation or others`), `:67` (`when others then denied`)
- **Scenario:** ถ้า insert ล้มด้วยเหตุอื่น (เช่น NOT NULL อนาคต) test จะนับเป็น "denied/blocked" แล้วผ่านทั้งที่ RLS อาจไม่ได้ทำงาน
- **Expected vs Actual:** ควร assert เจาะจง sqlstate — RLS = `42501`, enum = `22P02` / ปัจจุบันจับ `others` รวม (probe อิสระยืนยันว่าจริง ๆ เป็น RLS/enum ถูกต้อง แต่ตัว test เองไม่การันตี)
- **Recommendation:** เปลี่ยนเป็น `exception when sqlstate '42501'` (insufficient_privilege / RLS) และ `when sqlstate '22P02'` (invalid_text_representation) เท่านั้น
- **Test to add:** เพิ่มเคส assert `SQLSTATE` ให้ตรงชนิด error

### L3 · กฎ appears_in (กัปตันโก๊ะ ห้าม P1) เป็น advisory ไม่มี guard
- **Severity:** Low (informational) · **Evidence:** `0011:8` (คอมเมนต์ระบุ advisory), `lib/character/actions.ts:38-40` + `components/CharacterForms.tsx:84-89`
- **Scenario:** editor ติ๊ก P1 ให้กัปตันโก๊ะ หรือใส่ appears_in ให้ brand_motif ได้อิสระ — ไม่มีอะไรกันที่ DB/app
- **Expected vs Actual:** docs/05 §5.3 บอก "ห้ามปรากฏใน P1" / Actual บังคับไม่ได้ (ตั้งใจให้เป็น advisory ตามคอมเมนต์ migration)
- **Recommendation:** ไม่บล็อก PR — แต่ควรผูกกฎนี้เข้า QC checklist / Gate เชิงเนื้อหาในเฟสถัดไป (หรือ warning ใน UI)
- **Test to add:** (เมื่อทำ guard) เคสปฏิเสธ brand_motif ที่ appears_in นอก P1

### L4 · CircleCI เพิ่ม test เป็น list แบบ hardcode ไม่ใช่ glob
- **Severity:** Low · **Evidence:** `.circleci/config.yml:72` (เพิ่ม `rls_characters_test.sql` เข้า list มือ)
- **Scenario:** RLS test ไฟล์ใหม่ในอนาคตต้องจำเพิ่มเองในลิสต์ → เสี่ยง test ใหม่ไม่ถูกรันเงียบ ๆ
- **Expected vs Actual:** CLAUDE.md ระบุแนวทาง loop `ls 0*.sql` (auto-pick) / Actual test suite ยังเป็นลิสต์ตายตัว (รอบนี้เพิ่มถูกต้องแล้ว จึงเป็นแค่ maintainability)
- **Recommendation:** เปลี่ยน step เป็น `for t in supabase/tests/rls_*_test.sql; do ...` เพื่อ auto-pick
- **Test to add:** —

---

## ประเมิน 4 ด้านตามโจทย์
1. **Migration 0011 correctness:** ✓ ALTER `add column if not exists` + enum `duplicate_object` guard → idempotent · `type` NOT NULL มี default `'character'` → เพิ่มปลอดภัยแม้ตารางมีแถว · seed re-create 4 ตัวตรง docs/05 §5 · ดาวดวงน้อย=brand_motif · กัปตันโก๊ะ={P2,P3} ห้าม P1 · ไม่มี secret/PII · grant seed_puifun คงอยู่ (proacl ไม่มี PUBLIC)
2. **RLS coverage:** ✓ policy เดิม 0003 (`characters_select`=can_access_channel, `characters_write` FOR ALL=has_channel_write) ครอบคอลัมน์ใหม่โดยอัตโนมัติ (row-level ไม่ผูกคอลัมน์) · cross-workspace B เห็น 0/insert-update ถูกปฏิเสธ · viewer อ่านได้ เขียนไม่ได้ · 0011 ไม่เพิ่ม function ใหม่ (ยืนยัน) — seed_puifun ยัง SECURITY DEFINER + search_path=''
3. **Consistency กับ ADR:** ✓ `characters` พหูพจน์ (ADR-003) · channel-scoped FK→channels (ADR-004, มาจาก 0003) · RLS ครบ (ADR-001) · immutable: 0011 เป็นไฟล์ใหม่ ไม่แตะ 0001–0010 (ยืนยันจาก diff)
4. **Test / provenance:** ✓ harness ครอบ enum + cross-workspace + viewer + seed count=4 + motif type · TS unit ครอบ enum guard/slug/json/array/name · ข้อสังเกต test robustness = L2 · provenance gap เล็ก = L1

---

## Severity Count
| Critical | High | Medium | Low |
|:--:|:--:|:--:|:--:|
| 0 | 0 | 0 | 4 |

## Verdict: **GO** (merge PR #4 → main)

เหตุผล: ทั้ง 4 ด้านผ่าน · VERIFY รันจริงครบ (harness 6/6 + probe อิสระ 8 เคส + lint/typecheck/test 77/build ผ่านหมด) · ไม่มี secret · migration idempotent + NOT NULL ปลอดภัย · RLS กัน cross-workspace/viewer ได้จริง (พิสูจน์ด้วย probe อิสระ ไม่พึ่งคำเคลมของ test) · seed ตรง spec. Findings ทั้งหมดเป็น **Low** และมี workaround — ไม่บล็อกการ merge. แนะนำจัดการ L1 (created_by) และ L2 (assert sqlstate) เป็นงานตามหลัง (ไม่ใช่เงื่อนไข merge).

Confidence: **สูง** — verify ครบทุกชุดที่โจทย์กำหนด รันได้จริงบน Postgres 16 ในเครื่อง.
