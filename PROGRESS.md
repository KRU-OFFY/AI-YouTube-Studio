# สถานะงาน — ปุยฝัน (Puifun) / TOFFY AI YouTube Studio

> **อ่านไฟล์นี้ก่อนเริ่มทำงานต่อทุกครั้ง** แล้วดำเนินการจากส่วน "ขั้นตอนถัดไป" ด้านล่าง
> เมื่อคืบหน้า อย่าลืมอัปเดตวันที่ และย้ายงานที่เสร็จไปไว้ในส่วน "ทำเสร็จแล้ว"

**อัปเดตล่าสุด:** 24 ก.ค. 2026 (รอบ 3 — วางชุดเอกสารอ้างอิงครบ + รับ ADR Sprint 1 + CI เขียว)

---

## ภาพรวมโปรเจกต์
- ช่อง YouTube เด็กภาษาไทย ชื่อแบรนด์ **ปุยฝัน (Puifun)** — คาแรกเตอร์เมฆปุกปุย ธีมดาว/ก่อนนอน
- ระบบผลิต: **TOFFY AI YouTube Studio** (Next.js + Supabase + Vercel)
- ขอบเขต MVP: 7 เฟส จบที่ Export Production Package
- ตัวชี้วัดหลัก: rewatch rate และ asset reuse ratio (สำคัญกว่า RPM)

## ทำเสร็จแล้ว (Week 0)
- เอกสารโลกแบรนด์ (brand world)
- คาแรกเตอร์หลัก 3 ตัว: น้องปุย, มุ่ย, กัปตันโก๊ะ (มี prompt สร้างภาพ)
- 3 เสาเนื้อหา: นิทานก่อนนอน, เพลงร้องตาม, คลิปตลกสั้น + ซิกเนเจอร์ดาวเรืองแสงปิดท้ายนิทาน
- แบ็กล็อกไพลอต 10 ตอน + seed data spec + QC checklist
- รายงานเคลียร์ชื่อ: เลี่ยง "ปุยนุ่น" → ใช้ "ปุยฝัน" (ตรวจผ่านแล้ว)
- Task 0.1 scaffold prompt สำหรับ Claude Code
- เทมเพลต Rights Log CSV (ติดตามที่มาของ asset ที่ AI สร้าง)
- **Task 0.1 — Scaffold โปรเจกต์ Next.js + Supabase (เสร็จ 24 ก.ค. 2026)**
  - โครง Next.js App Router + TypeScript
  - Supabase client (browser / server / admin) ใน `lib/supabase/`
  - Migration เริ่มต้น `supabase/migrations/0001_init.sql`
    (characters / content_pillars / episodes / assets / rights_log)
  - หน้า `/dashboard` มี health check ของ Supabase
  - `.env.example`, `.gitignore`, `README.md`, `CLAUDE.md`, `docs/QC-checklist.md`
- **นำเข้าเอกสารส่งมอบ Week 0 + seed data (เสร็จ 24 ก.ค. 2026)**
  - `docs/00-WEEK0-HANDOFF.md`, `docs/05-SEED-DATA.md`, `docs/06-NAME-CLEARANCE.md`
  - `docs/pilots/pilot-01-theme-song.md`, `docs/pilots/pilot-02-pui-lost-blanket.md`
  - `supabase/seed.sql` — 3 pillars + 4 ตัวละคร + 10 ตอน (ตอน #1/#2 มีบท) ทดสอบรันจริงบน Postgres ผ่าน + idempotent
  - อัปเดต `CLAUDE.md` เพิ่มหัวข้อ Source of Truth

## กำลังทำ / ค้างอยู่
- **Task 1.1 (Auth) — เสนอแผนแล้ว รออนุมัติก่อนลงมือ** (ทำ Inspect → Plan เสร็จ)

## ✅ ข้อตัดสินจากฝั่งวางแผน (ADR — ปิดคำถามค้างทั้ง 4 ข้อแล้ว)
ดูฉบับเต็มที่ `docs/07-DECISIONS-sprint1.md`
1. **ADR-001:** workspace/channel = **ตารางจริง + RLS** (ไม่ใช่ config) → Task 1.2 / 1.3
2. **ADR-002:** `forbidden_words` = ตาราง config (channel-scoped) seed จาก docs/05 · QC checklist คง docs ไปก่อน (สร้างตาราง Sprint 6)
3. **ADR-003:** ยึดชื่อ **`rights_records`** (ไม่ใช่ `rights_log`) → ต้องแก้ scaffold + กฎ naming อยู่ใน `AGENTS.md` แล้ว
4. **ADR-004:** เบรก Episodes UI — จัดลำดับราก→ยอด; pillars/characters/episodes เป็น channel-scoped (FK → channels → workspaces)

## 📌 หนี้ที่ต้องเคลียร์ก่อน/ระหว่าง Sprint 1
- แก้ scaffold: เปลี่ยนตาราง `rights_log` → `rights_records` ใน migration 0001 (ADR-003) — จะทำตอนถึงจังหวะที่ไม่ชนกับ Task ที่รันอยู่
- ปรับ `supabase/seed.sql`: เพิ่ม seed row workspace "Puifun Studio" + channel "ปุยฝัน" แล้วผูก FK ให้ pillars/characters/episodes เข้ากับ channel_id (หลัง Task 1.3)

## ขั้นตอนถัดไป — Sprint 1 (ทำตามลำดับ ห้ามข้าม)
1. **Task 1.1 — Auth (FR-001)** ← กำลังรออนุมัติแผน
2. **Task 1.2 — workspaces + workspace_members + RLS (FR-002)**
3. **Task 1.3 — channels (FK→workspace) + Gate 0 + RLS**
4. **ปรับ seed** — workspace/channel เป็น seed row → pillars/characters/episodes ผูก FK
5. **Task 1.4 — audit log (FR-013)**
6. **Auditor** ตรวจจบ Sprint 1 (เปิด session ใหม่, เกณฑ์: Critical=0, High=0)
7. **จากนั้น** ค่อยทำ Episodes UI

## งานฝั่งเจ้าของ (ผมทำแทนไม่ได้ — ทำคู่ขนาน)
- **จองแฮนเดิล YouTube `@puifun`** — ด่วนสุด
- สร้างโปรเจกต์ Supabase จริง → ใส่ค่าใน `.env.local` (Task 1.1 ต้องใช้ตอนทดสอบ login จริง)
- Track A: สร้าง anchor image น้องปุย/มุ่ย + generate เพลงธีม Pilot #1 (Suno) + จด Rights Log

## ข้อจำกัดที่ต้องเผื่อไว้เวลาวางแผน
- Claude สร้างไฟล์ / รันโค้ดในแซนด์บ็อกซ์ / ค้นเว็บได้ แต่ **ติดตั้งซอฟต์แวร์บนเครื่องคุณไม่ได้, สมัครบัญชีบริการภายนอกแทนไม่ได้, และควบคุมเบราว์เซอร์แทนไม่ได้** — งานพวกนี้คุณต้องลงมือเอง
- Claude เริ่มทำงานเองอัตโนมัติไม่ได้ ต้องให้คุณเปิดแชตแล้วสั่ง "ทำต่อ"

## บันทึกการตัดสินใจ / โน้ตสำคัญ
- เลือกชื่อ "ปุยฝัน" เพราะชื่อเดิม "ปุยนุ่น" ติดแบรนด์เชิงพาณิชย์ + เพลงดังในผลค้นหา + มีข่าวเชิงลบพ่วง
- Scaffold ใช้ Next.js 14 (App Router) + `@supabase/ssr` เพื่อให้เข้ากับ Vercel/Server Components
- Package manager = npm (ถ้าเปลี่ยนภายหลัง ต้องอัปเดต CLAUDE.md ด้วย)
