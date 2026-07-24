# CLAUDE.md — บริบทโปรเจกต์สำหรับ Claude Code

## อ่านก่อนเริ่มงานทุกครั้ง
1. เปิด `PROGRESS.md` ในรากโปรเจกต์ — อ่านสถานะล่าสุด แล้วทำจากส่วน "ขั้นตอนถัดไป"
2. เมื่อทำเสร็จแต่ละงาน อัปเดต `PROGRESS.md` ให้ตรงกับความจริง (ย้ายไปส่วน "ทำเสร็จแล้ว" + เขียนขั้นตอนถัดไป)

## เกี่ยวกับโปรเจกต์
- ชื่อ: **TOFFY AI YouTube Studio**
- ปลายทาง: ป้อนคอนเทนต์ให้ช่อง YouTube เด็กภาษาไทยแบรนด์ **ปุยฝัน (Puifun)**
- คอนเทนต์ประเภท **Made for Kids** — ต้องระวังเรื่อง COPPA / นโยบาย YouTube Kids
- ตัวชี้วัดหลัก: rewatch rate + asset reuse ratio (สำคัญกว่า RPM)

## เอกสารอ้างอิง (Source of Truth) — อ่านก่อนตัดสินใจเรื่องเนื้อหา
1. `PROGRESS.md` — สถานะงาน / ขั้นตอนถัดไป (อ่านก่อนเสมอ)
2. `docs/00-WEEK0-HANDOFF.md` — สรุปส่งมอบ Week 0 + งานที่เจ้าของต้องทำเอง
3. `docs/05-SEED-DATA.md` — Workspace, Channel, Character Bible, Idea Backlog 10 ตอน, QC checklist, forbidden words
4. `docs/06-NAME-CLEARANCE.md` — เหตุผลที่เลี่ยง "ปุยนุ่น" → ใช้ "ปุยฝัน"
5. `docs/pilots/` — บทตอน Pilot (เพลงธีม / นิทาน) พร้อม prompt ผลิต
6. `docs/04-BUSINESS-CONTEXT.md` — บริบทแบรนด์และข้อจำกัดทางธุรกิจ *(ยังไม่มีในรีโป — รอฝั่งวางแผนส่งมา)*
7. `supabase/seed.sql` — seed ข้อมูลจริงชุดแรกเข้าตาราง (แปลงจาก `05-SEED-DATA.md`)

## Tech stack
- Next.js (App Router) + TypeScript
- Supabase (Postgres + Auth + Storage)
- Vercel สำหรับ deploy (ยังไม่ deploy ในเฟส scaffold)
- Package manager: **npm** (ห้ามใช้ตัวอื่นถ้าไม่ได้บอก)

## เค้าโครงโฟลเดอร์
```
app/                Next.js routes
components/         UI ซ้ำ ๆ
lib/supabase/       Supabase client (browser / server / admin)
supabase/migrations SQL migration
docs/               เอกสาร (QC checklist ฯลฯ)
```

## กติกา
- ทำทีละขั้น อธิบายสั้น ๆ ว่ากำลังจะทำอะไรก่อนลงมือ
- ถ้าติดสินใจอะไรที่กระทบโครงสร้างสำคัญ (schema, dependency ใหญ่, การเปลี่ยน framework) **ถามก่อน อย่าเดา**
- ห้ามรันคำสั่งทำลาย (drop table, rm -rf, git push --force) โดยไม่ถาม
- ห้ามใส่ / commit ค่า secret ใด ๆ — `.env*` อยู่ใน `.gitignore` แล้ว รักษาไว้อย่างนั้น
- `SUPABASE_SERVICE_ROLE_KEY` ห้ามหลุดถึงฝั่ง browser
- ถ้าเจอ error ที่ไม่ชัดเจน สรุปให้ผมอ่านก่อนจะแก้แบบเดา

## Commands
```bash
npm install
npm run dev
npm run build
npm run typecheck
npm run lint
```

## Branch convention
- ทำงานบนบรานช์ที่แชตสั่ง (ตอนนี้: `claude/toffy-collaboration-system-wnnlpv`)
- commit บ่อย ๆ ด้วยข้อความสั้นและอธิบาย "ทำไม" ไม่ใช่แค่ "อะไร"
