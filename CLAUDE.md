# CLAUDE.md — บริบทโปรเจกต์สำหรับ Claude Code

## ภาษา
- **สื่อสารกับผู้ใช้เป็นภาษาไทยทั้งหมดเสมอ** (ไม่ต้องรอให้สั่ง) — ครอบคลุม:
  - ข้อความแชต, คำอธิบาย, สรุปทุกอย่าง
  - คอมเมนต์ / คำอธิบาย / หัวข้อ Pull Request และ Issue บน GitHub
  - ข้อความ commit (subject + body)
- ยกเว้นเฉพาะสิ่งที่ต้องเป็นภาษาอังกฤษด้วยเหตุผลทางเทคนิค (แปลไทยแล้วระบบพัง):
  - โค้ด, ชื่อไฟล์, ชื่อตาราง/คอลัมน์, ชื่อตัวแปร/ฟังก์ชัน
  - ไวยากรณ์คำสั่ง git / npm / SQL
  - trailer ที่ระบบบังคับท้าย commit (เช่น `Co-Authored-By:`)

## อ่านก่อนเริ่มงานทุกครั้ง
1. เปิด `PROGRESS.md` ในรากโปรเจกต์ — อ่านสถานะล่าสุด แล้วทำจากส่วน "ขั้นตอนถัดไป"
2. เมื่อทำเสร็จแต่ละงาน อัปเดต `PROGRESS.md` ให้ตรงกับความจริง (ย้ายไปส่วน "ทำเสร็จแล้ว" + เขียนขั้นตอนถัดไป)

## เกี่ยวกับโปรเจกต์
- ชื่อ: **TOFFY AI YouTube Studio**
- ปลายทาง: ป้อนคอนเทนต์ให้ช่อง YouTube เด็กภาษาไทยแบรนด์ **ปุยฝัน (Puifun)**
- คอนเทนต์ประเภท **Made for Kids** — ต้องระวังเรื่อง COPPA / นโยบาย YouTube Kids
- ตัวชี้วัดหลัก: rewatch rate + asset reuse ratio (สำคัญกว่า RPM)

## เอกสารอ้างอิง (Source of Truth) — อ่านตามลำดับก่อนตัดสินใจ
1. `PROGRESS.md` — สถานะงาน / ขั้นตอนถัดไป (อ่านก่อนเสมอ)
2. `AGENTS.md` — กฎการทำงาน + กฎ naming ของตาราง (ADR)
3. `docs/00-PROJECT-CONTEXT.md` — บริบทโปรเจกต์ภาพรวม
4. `docs/02-SYSTEM-SPEC.md` — สเปกระบบ (FR / NFR / Permission Matrix)
5. `docs/03-ARCHITECTURE-AND-DATA.md` — Data Model, Security, RLS
6. `docs/01-SYSTEM-WORKFLOW.md` — เวิร์กโฟลว์ระบบ
7. `plans/IMPLEMENTATION-ROADMAP.md` — โรดแมป (เน้น Phase 1)
8. `docs/04-BUSINESS-CONTEXT.md` — บริบทแบรนด์และข้อจำกัดทางธุรกิจ
9. `docs/05-SEED-DATA.md` — Workspace, Channel, Character Bible, Idea Backlog 10 ตอน, QC checklist, forbidden words
10. `docs/06-NAME-CLEARANCE.md` — เหตุผลที่เลี่ยง "ปุยนุ่น" → ใช้ "ปุยฝัน"
11. `docs/07-DECISIONS-sprint1.md` — บันทึกการตัดสินใจสถาปัตยกรรม (ADR สำหรับ Sprint 1)
12. `docs/00-WEEK0-HANDOFF.md` — สรุปส่งมอบ Week 0 + งานที่เจ้าของต้องทำเอง
13. `docs/pilots/` — บทตอน Pilot (เพลงธีม / นิทาน) พร้อม prompt ผลิต
14. `prompts/PLAYBOOK-Sprint-1-Claude-Code.md` — ชุดคำสั่ง Sprint 1 (Task 1.1–1.4)
15. `checklists/QUALITY-GATES.md` — เกณฑ์ผ่านแต่ละ gate
16. `supabase/seed.sql` — seed ข้อมูลจริงชุดแรกเข้าตาราง (แปลงจาก `05-SEED-DATA.md`)

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

---

# สำหรับรอบตรวจ (Auditor — Principal Architect / Security Reviewer)
> ใช้เมื่อรัน Prompt Auditor ท้าย Sprint ในหน้าต่าง Claude แยก (คนละ session กับผู้พัฒนา)
> รอบตรวจแรก **ห้ามแก้โค้ด** — ให้รายงาน finding แล้วบันทึกลง `audits/`

## Architectural Invariants (ต้องไม่ถูกละเมิด)
- Domain ไม่ผูกกับ Provider SDK · UI ไม่เข้าถึง Secret หรือ Provider โดยตรง
- State Transition และ Approval Gate บังคับใช้ฝั่ง Server · Approval ผูกกับ Version เสมอ
- Asset มี Provenance/Usage Note · Published Video ผูกกับ Version ของ Script/Render/Metadata ที่ใช้จริง
- Generation/Render/Publish Job ต้อง Retry ได้อย่างปลอดภัยและ Idempotent
- Audit Log ห้ามเก็บ Secret หรือ Raw Sensitive Payload · Policy Checklist ต้อง Versioned และ Configurable

## Review Focus
- **Requirements:** Requirement→Module→Data→API→Test, scope creep, missing acceptance, workflow-vs-impl conflict
- **Architecture:** module boundary, coupling/circular dep, provider leakage, transaction boundary, SPOF, migration safety
- **Content Pipeline:** invalid state, version/approval mismatch, asset provenance gap, QC bypass, publish without gate
- **Security:** broken access control, workspace data leakage, secret exposure, unsafe upload, webhook verification, log redaction, rate limit/abuse
- **Operations:** retry storm, duplicate generation/publish, stuck job, missing alert, backup/restore gap, cost runaway

## รูปแบบ Finding
ID · Title · Severity (Critical/High/Medium/Low) · Confidence · Evidence (file/line/function/test) · Scenario · Expected vs Actual · Impact · Root Cause · Recommendation · Test to Add · Rollback/Risk

## Severity
- **Critical:** ข้อมูล/Secret รั่ว, เผยแพร่ผิดช่อง/ผิดสิทธิ์, ข้อมูลสูญหาย, ระบบหลักใช้ไม่ได้
- **High:** ข้าม Approval/QC, Version ผิด, Job ซ้ำสร้างค่าใช้จ่ายสูง, Publish ผิด Metadata
- **Medium:** UX/Performance/Maintainability หรือ gap ที่ยังมี workaround
- **Low:** Quality/Clarity/Technical Debt

## Output
บันทึกลง `audits/` + สรุป: Executive Summary · Architecture Map · Traceability Gap · Findings Table · Test Gap · Remediation Roadmap · **Go / Conditional Go / No-Go**

## ห้ามในรอบตรวจ
- ห้ามแก้โค้ดในรอบแรก · ห้าม Deploy/เปลี่ยน Production · ห้ามอ่าน/พิมพ์ค่า Secret
- ห้ามเสนอ rewrite ทั้งระบบโดยไม่มีหลักฐาน · ห้ามรายงาน generic best practice ที่ไม่เชื่อมกับ repo จริง
- ห้ามประกาศ Pass หากไม่ได้รันคำสั่ง build/test ที่มีจริง
