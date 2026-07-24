# สถานะงาน — ปุยฝัน (Puifun) / TOFFY AI YouTube Studio

> **อ่านไฟล์นี้ก่อนเริ่มทำงานต่อทุกครั้ง** แล้วดำเนินการจากส่วน "ขั้นตอนถัดไป" ด้านล่าง
> เมื่อคืบหน้า อย่าลืมอัปเดตวันที่ และย้ายงานที่เสร็จไปไว้ในส่วน "ทำเสร็จแล้ว"

**อัปเดตล่าสุด:** 24 ก.ค. 2026 (รอบ 2 — เพิ่มเอกสาร Week 0 + seed.sql)

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
- (เติมตรงนี้เมื่อเริ่มงานใหม่)

## ⚠️ ต้องให้ฝั่งวางแผน (สมอง) ตัดสิน — ค้างอยู่
1. **ช่องว่าง schema:** `05-SEED-DATA.md` มี **Workspace** และ **Channel** (+ Audience Profile) แต่ schema 0001 ยังไม่มีตารางรองรับ
   → จะเพิ่มตาราง `workspaces` / `channels` ใน migration 0002 ไหม หรือถือเป็น config คงที่ตอนนี้?
2. **`forbidden_words` + QC checklist** จะเก็บเป็นตาราง config ในระบบ หรือคงไว้เป็นไฟล์ docs ก่อน?
3. **`docs/04-BUSINESS-CONTEXT.md`** ถูกอ้างถึงแต่ยังไม่ได้ส่งเข้ารีโป — ขอไฟล์จากฝั่งวางแผน
4. ตั้งชื่อตาราง rights: scaffold ใช้ `rights_log` แต่ handoff พูดถึง `rights_records` — ยึดชื่อไหน?

## ขั้นตอนถัดไป (ทำอันบนสุดก่อน)
1. **จองแฮนเดิล YouTube `@puifun`** ก่อนโดนคนอื่นจอง — ด่วนสุด
2. สร้างโปรเจกต์ Supabase จริง → เอาค่ามาใส่ `.env.local` → รัน migration 0001 → รัน `supabase/seed.sql`
3. `npm install` แล้ว `npm run dev` ให้แน่ใจว่าหน้า `/dashboard` ขึ้นแถบเขียว
4. ตอบ 4 คำถามในหัวข้อ "ต้องให้ฝั่งวางแผนตัดสิน" ด้านบน
5. เฟสถัดไปของ TOFFY: หน้าจัดการ Episodes (list / create / edit) อ่านจากตาราง `episodes` ที่ seed ไว้แล้ว
6. เริ่มผลิตเนื้อหาแบบแมนนวลคู่ขนานตั้งแต่ Week 1 (ไม่ต้องรอระบบเสร็จ)

## ข้อจำกัดที่ต้องเผื่อไว้เวลาวางแผน
- Claude สร้างไฟล์ / รันโค้ดในแซนด์บ็อกซ์ / ค้นเว็บได้ แต่ **ติดตั้งซอฟต์แวร์บนเครื่องคุณไม่ได้, สมัครบัญชีบริการภายนอกแทนไม่ได้, และควบคุมเบราว์เซอร์แทนไม่ได้** — งานพวกนี้คุณต้องลงมือเอง
- Claude เริ่มทำงานเองอัตโนมัติไม่ได้ ต้องให้คุณเปิดแชตแล้วสั่ง "ทำต่อ"

## บันทึกการตัดสินใจ / โน้ตสำคัญ
- เลือกชื่อ "ปุยฝัน" เพราะชื่อเดิม "ปุยนุ่น" ติดแบรนด์เชิงพาณิชย์ + เพลงดังในผลค้นหา + มีข่าวเชิงลบพ่วง
- Scaffold ใช้ Next.js 14 (App Router) + `@supabase/ssr` เพื่อให้เข้ากับ Vercel/Server Components
- Package manager = npm (ถ้าเปลี่ยนภายหลัง ต้องอัปเดต CLAUDE.md ด้วย)
