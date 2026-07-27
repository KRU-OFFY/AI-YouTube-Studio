# Playbook สั่งงาน Claude Code — Sprint 1
## Foundation + Auth + Workspace + Channel (สัปดาห์ 1–2)

> **ไฟล์นี้คืออะไร:** ชุดคำสั่งสำเร็จรูปเรียงตามลำดับ ก็อปทีละบล็อกวางใน Claude Code ได้เลย
> ผมสั่ง Claude Code บนเครื่องคุณโดยตรงไม่ได้ (มันรันบนเครื่องคุณ) — ไฟล์นี้คือวิธีที่ผมช่วยได้ดีที่สุด
> **ทุก prompt สั่งให้ Claude Code สื่อสารภาษาไทยและหยุดรออนุมัติก่อนลงมือเสมอ**

---

## ⚠️ ก่อนเริ่ม — ต้องทำครบ 4 ข้อนี้ก่อน

- [ ] ติดตั้ง Node.js, Git, VS Code, Claude Code แล้ว (`node -v`, `git -v`, `claude` ใช้ได้)
- [ ] สมัคร GitHub / Supabase / Vercel แล้ว
- [ ] วางไฟล์ Starter Kit + ไฟล์จากผม (`docs/04, 05, 06`, `prompts/`) ลง repo แล้ว
- [ ] **ผ่าน Task 0.1 (Scaffold) แล้ว** — `npm run dev/lint/typecheck/test/build` ผ่านครบ

> ถ้ายังไม่ผ่าน Task 0.1 ให้ใช้ `prompts/TASK-0.1-SCAFFOLD.md` ก่อน อย่าเพิ่งเริ่มไฟล์นี้

---

## วิธีทำงานแต่ละ Task (อ่านครั้งเดียว ใช้ซ้ำทุก task)

```
1. เปิด Terminal ในโฟลเดอร์โปรเจกต์ → พิมพ์ claude
2. ก็อป Prompt ของ task นั้นทั้งบล็อก → วาง → Enter
3. Claude Code จะ "เสนอแผน" แล้วหยุด → คุณอ่าน ถ้าโอเคพิมพ์: อนุมัติ ลงมือได้
4. Claude Code พัฒนา + เขียน test เสร็จ → คุณรันทดสอบจริงตาม Acceptance
5. ผ่านครบ → พิมพ์ใน Terminal: git add -A && git commit -m "ข้อความ"
6. ทำ task ถัดไป
7. จบทั้ง Sprint → รัน Prompt Auditor (ท้ายไฟล์) ในหน้าต่าง Claude ใหม่
```

**กฎเหล็ก:** ถ้า Claude Code จะทำอะไรนอกเหนือจากที่ prompt สั่ง (เช่นเพิ่ม library แปลก ๆ หรือแตะฐานข้อมูลก่อนถึงเวลา) ให้พิมพ์ว่า "หยุด อธิบายก่อนว่าทำไม" — อย่าเพิ่งอนุมัติ

---

# ═══════════════════════════════
# PROMPT 0 — Bootstrap (วางครั้งเดียวตอนเปิด session ใหม่)
# ═══════════════════════════════

```
คุณคือ Senior Full-stack Engineer ของโปรเจกต์ Puifun Content Factory

ก่อนทำงานใด ๆ ให้อ่านไฟล์เหล่านี้ตามลำดับแล้วสรุปสั้น ๆ ให้ผมเห็นว่าคุณเข้าใจตรงกัน:
1. AGENTS.md — กฎที่คุณต้องปฏิบัติทุกข้อ
2. docs/00-PROJECT-CONTEXT.md
3. docs/02-SYSTEM-SPEC.md — เน้น FR-001, FR-002, FR-013 และ Permission Matrix
4. docs/03-ARCHITECTURE-AND-DATA.md — เน้น Data Model, Security, RLS
5. docs/04-BUSINESS-CONTEXT.md
6. docs/05-SEED-DATA.md
7. plans/IMPLEMENTATION-ROADMAP.md — เน้น Phase 1

บริบทเกี่ยวกับผม: ผมเป็นเจ้าของโปรเจกต์ เพิ่งเริ่มเขียนโค้ด
- สื่อสารกับผมเป็นภาษาไทยเสมอ
- อธิบายสิ่งที่ทำด้วยภาษามือใหม่เข้าใจ บอกว่าไฟล์แต่ละไฟล์ทำหน้าที่อะไร
- ทุก task ให้ทำตามลำดับ: Inspect → Plan → (หยุดรอผมพิมพ์ "อนุมัติ") → Implement → Verify (รันจริง แสดงผลจริง) → Summary
- ห้ามบอกว่า test ผ่านโดยไม่ได้รันจริง
- ห้ามทำเกินขอบเขตที่แต่ละ task กำหนด ถ้าจะเกินต้องถามก่อน

ตอบกลับด้วยสรุปความเข้าใจ + ยืนยันว่าพร้อมรับ Task แรก แล้วหยุดรอผม
```

---

# ═══════════════════════════════
# TASK 1.1 — Supabase Auth (FR-001)
# ═══════════════════════════════

```
Task 1.1 — Authentication ด้วย Supabase

Requirement: FR-001 (Identity & Access) | NFR-002 (Security)

เป้าหมาย:
1. เชื่อมต่อ Supabase (ใช้ค่าจาก .env.local — ผมจะใส่ค่าจริงเอง ห้าม hardcode)
2. Auth ด้วยอีเมล + รหัสผ่าน (sign up / log in / log out)
3. จัดการ session ฝั่ง server (server-side session, ปลอดภัย ไม่เก็บ token ใน localStorage แบบ raw)
4. หน้า /login, /signup และปุ่ม logout
5. Middleware กันหน้าใน (app) ที่ต้องล็อกอินก่อน — ยังไม่ล็อกอินให้ redirect ไป /login
6. หน้าแรกหลังล็อกอินแสดงอีเมลผู้ใช้ที่ล็อกอินอยู่

ข้อกำหนดความปลอดภัย (สำคัญ):
- ห้าม hardcode URL/key ของ Supabase ในโค้ด — อ่านจาก environment variable เท่านั้น
- ห้าม log รหัสผ่านหรือ token ลง console
- ตรวจ session ฝั่ง server ทุกครั้ง ไม่เชื่อฝั่ง client อย่างเดียว

Acceptance Criteria (ผมจะใช้ตรวจ):
- [ ] สมัคร → ล็อกอิน → เห็นอีเมลตัวเอง → logout ได้ครบวงจร
- [ ] เข้า URL หน้าใน (app) โดยไม่ล็อกอิน → ถูก redirect ไป /login
- [ ] กรอกอีเมลผิดรูปแบบ / รหัสผ่านสั้นเกิน → มี error message ที่อ่านเข้าใจ
- [ ] npm run lint / typecheck / test / build ผ่านครบ
- [ ] git diff ไม่มี secret หลุด

เขียน unit test อย่างน้อยสำหรับ validation ของฟอร์ม
เริ่มจาก Inspect → Plan แล้วหยุดรอผมอนุมัติ
```

**หลังผ่าน:** `git commit -m "feat: supabase email auth (FR-001)"`

---

# ═══════════════════════════════
# TASK 1.2 — Workspace + Row Level Security (FR-002)
# ═══════════════════════════════

```
Task 1.2 — Workspace และการแยกข้อมูลด้วย Row Level Security

Requirement: FR-002 (Workspace & Multi-tenancy) | อ้าง Data Model ใน docs/03

เป้าหมาย:
1. สร้าง migration ตาราง:
   - workspaces (id, name, default_language, timezone, currency, created_by, created_at)
   - workspace_members (workspace_id, user_id, role, created_at) — role: owner / editor / viewer
2. เปิด Row Level Security (RLS) ทั้งสองตาราง:
   - ผู้ใช้เห็น/แก้ได้เฉพาะ workspace ที่ตัวเองเป็น member
   - policy เขียนชัดเจนแยก select / insert / update / delete
3. หน้าจอ: สร้าง workspace, แก้ชื่อ, เลือก timezone (default Asia/Bangkok), currency (default THB)
4. เมื่อผู้ใช้สร้าง workspace → เพิ่มตัวเองเป็น member role=owner อัตโนมัติ

ข้อกำหนดความปลอดภัย (สำคัญมาก — นี่คือหัวใจ):
- RLS ต้องบังคับที่ระดับฐานข้อมูล ไม่ใช่แค่ซ่อนปุ่มใน UI
- ทดสอบว่า user A query ข้อมูล workspace ของ user B ไม่ได้แม้ยิงตรงผ่าน API

อธิบายให้ผมเข้าใจ: RLS คืออะไร ทำไมต้องมี และ policy ที่คุณเขียนแต่ละอันแปลว่าอะไร

Acceptance Criteria:
- [ ] สร้าง 2 บัญชี → แต่ละคนสร้าง workspace → มองไม่เห็นของกันและกัน (ทดสอบจริง)
- [ ] พยายามดึงข้อมูล workspace คนอื่นผ่าน query ตรง → ถูกปฏิเสธที่ระดับ DB
- [ ] migration รันแล้ว rollback ได้
- [ ] lint / typecheck / test / build ผ่าน

เริ่มจาก Inspect → Plan แล้วหยุดรอผมอนุมัติ
พิเศษ: ก่อน implement ให้อธิบาย RLS policy เป็นภาษาไทยให้ผมเข้าใจก่อน
```

**หลังผ่าน:** `git commit -m "feat: workspace + RLS multi-tenancy (FR-002)"`

---

# ═══════════════════════════════
# TASK 1.3 — Channel Profile + Gate 0 (FR-002 ต่อ)
# ═══════════════════════════════

```
Task 1.3 — Channel Profile พร้อม Gate อนุมัติก่อนใช้งาน

Requirement: FR-002 | อ้าง docs/04-BUSINESS-CONTEXT.md และ docs/05-SEED-DATA.md

เป้าหมาย:
1. migration ตาราง channels ผูกกับ workspace รองรับฟิลด์ตาม docs/05 หัวข้อ 2:
   name, slug, handle, primary_language, made_for_kids_default (default true),
   audience_age_range, tone_of_voice, visual_style, publishing_cadence,
   forbidden_elements (เก็บเป็น array/json), status (draft / approved)
2. RLS: channel มองเห็น/แก้ได้เฉพาะ member ของ workspace นั้น
3. ฟอร์มสร้าง/แก้ channel ครบทุกฟิลด์ — made_for_kids ติ๊กเป็น true มาก่อน
4. Gate 0: channel ที่ status=draft ยังสร้าง Content Project ไม่ได้
   ต้องกด "อนุมัติ Channel" ให้ status=approved ก่อน (บังคับฝั่ง server ไม่ใช่แค่ซ่อนปุ่ม)

Acceptance Criteria:
- [ ] สร้าง channel "ปุยฝัน" ด้วยข้อมูลจริงจาก docs/05 สำเร็จ
- [ ] made_for_kids เป็น true โดย default
- [ ] channel ที่ยังไม่อนุมัติ → พยายามสร้าง project ผ่าน API ตรง ๆ ถูกปฏิเสธฝั่ง server
- [ ] lint / typecheck / test / build ผ่าน

เริ่มจาก Inspect → Plan แล้วหยุดรอผมอนุมัติ
```

**หลังผ่าน:** `git commit -m "feat: channel profile + approval gate 0 (FR-002)"`
**แล้วป้อนข้อมูลจริง:** สร้าง channel "ปุยฝัน" ตาม `docs/05-SEED-DATA.md` = ข้อมูลจริงชุดแรกเข้าระบบ 🎉

---

# ═══════════════════════════════
# TASK 1.4 — Audit Log พื้นฐาน (FR-013)
# ═══════════════════════════════

```
Task 1.4 — Audit Log พื้นฐาน

Requirement: FR-013 (Auditability) — เริ่มวางรากตั้งแต่ตอนนี้ ไม่รอทีหลัง

เป้าหมาย:
1. migration ตาราง audit_logs:
   id, workspace_id, actor_user_id, action, entity_type, entity_id,
   result (success/failure), metadata (json), created_at
2. บันทึก log อัตโนมัติเมื่อเกิด action สำคัญที่ทำไปแล้วใน Task 1.1–1.3:
   - สร้าง/แก้ workspace
   - สร้าง/แก้/อนุมัติ channel
   - login / logout (บันทึกแค่ success/failure ห้ามบันทึกรหัสผ่าน)
3. หน้าจอง่าย ๆ ดู audit log ล่าสุดของ workspace (เรียงใหม่ไปเก่า)
4. ทำเป็น helper function กลางที่ task อื่นเรียกใช้ต่อได้ (reusable)

ข้อกำหนดความปลอดภัย:
- ห้ามบันทึกข้อมูลอ่อนไหว (รหัสผ่าน, token) ลง audit log
- audit log แก้ไข/ลบไม่ได้จากฝั่ง UI (append-only)

Acceptance Criteria:
- [ ] ทำ action ใน Task 1.1–1.3 แล้วมี log บันทึกครบ
- [ ] audit log ของ workspace อื่นมองไม่เห็น (RLS)
- [ ] ไม่มีข้อมูลอ่อนไหวใน log
- [ ] lint / typecheck / test / build ผ่าน

เริ่มจาก Inspect → Plan แล้วหยุดรอผมอนุมัติ
```

**หลังผ่าน:** `git commit -m "feat: base audit log (FR-013)"`

---

# ═══════════════════════════════
# PROMPT AUDITOR — ตรวจจบ Sprint (เปิด Claude session ใหม่)
# ═══════════════════════════════

> **สำคัญ:** เปิดหน้าต่าง/แชต Claude **ใหม่** แยกจาก session ที่ใช้พัฒนา — เพื่อไม่ให้ "ผู้สร้างตรวจงานตัวเอง"

```
คุณคือ Principal Architect และ Security Reviewer ที่เป็นอิสระจากผู้พัฒนา
หน้าที่ของคุณคือตรวจสอบโค้ดที่เพิ่งสร้างใน Sprint 1 ไม่ใช่เขียนโค้ดใหม่

อ่าน CLAUDE.md เพื่อรับทราบเกณฑ์การตรวจ แล้วตรวจ codebase ปัจจุบันตามหมวดเหล่านี้:

1. Security
   - มี secret / API key / URL ฐานข้อมูล hardcode ในโค้ดหรือ git หรือไม่
   - RLS บังคับที่ระดับฐานข้อมูลจริงหรือแค่ซ่อนใน UI
   - session ตรวจฝั่ง server จริงหรือไม่
   - มีการ log ข้อมูลอ่อนไหว (รหัสผ่าน/token) หรือไม่

2. Multi-tenancy Isolation
   - user หนึ่งเข้าถึงข้อมูล workspace ของอีก user ได้หรือไม่ (ลองหาช่องโหว่)

3. Approval Gate
   - channel ที่ยังไม่อนุมัติ สร้าง project ได้หรือไม่ (ต้องไม่ได้)
   - bypass ผ่าน API ตรงได้หรือไม่

4. Audit & Correctness
   - audit log append-only จริงหรือไม่
   - test ครอบคลุม critical path หรือไม่ มี test ที่ fake ผ่านหรือไม่

รูปแบบผลตรวจ: จัดแต่ละ finding เป็นระดับ Critical / High / Medium / Low
พร้อมระบุไฟล์ บรรทัด และวิธีแก้ที่แนะนำ
สรุปท้ายด้วยคำตัดสิน: Go / Conditional Go / No-Go สำหรับขึ้น Sprint 2

สื่อสารเป็นภาษาไทย บันทึกผลลง audits/sprint-1-audit.md
```

**เกณฑ์ผ่าน Sprint 1:** Critical = 0 และ High = 0 (หรือมีบันทึกเหตุผลยอมรับความเสี่ยงชัดเจน) จึงขึ้น Sprint 2

---

## หลังจบ Sprint 1 — Track A ต้องเดินด้วย

อย่าลืม dual-track: สัปดาห์ 1–2 ฝั่งคอนเทนต์ต้องมี
- [ ] สร้าง anchor image น้องปุย + มุ่ย (ล็อกหน้าตาถาวร)
- [ ] generate เพลงธีมจาก Pilot #1 ด้วย Suno
- [ ] บันทึกทุก asset ลง Rights Log

**ถ้าเวลาชนกัน Track A ชนะเสมอ** — ระบบช้าได้ ช่องช้าไม่ได้

---

## เมื่อไหร่ควรกลับมาหาผม

- Claude Code เสนอแผนแล้วคุณไม่แน่ใจว่าควรอนุมัติไหม → ส่งแผนมาให้ผมช่วยดู
- ตรวจแล้วเจอ finding Critical/High แต่ไม่รู้จะแก้ยังไง → ส่งผลตรวจมา
- ผ่าน Sprint 1 แล้ว → ผมทำ Playbook Sprint 2 (Character + Idea + State Machine) ให้ต่อ
- อยากได้บท Pilot #3 หรือ Shorts เพิ่มระหว่างรอ → บอกได้เลย
