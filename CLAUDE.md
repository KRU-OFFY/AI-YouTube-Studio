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

## Security & Audit — กฎถาวร (ยึดทุก Task ที่เกี่ยวกับ log / auth / RLS)
- **APPEND-ONLY จริงที่ DB เสมอ:** ไม่ grant UPDATE/DELETE ให้ client + trigger `BEFORE UPDATE/DELETE → RAISE`
- **เขียน audit ผ่าน RPC/server เท่านั้น:** ไม่มี INSERT policy ตรงให้ client; actor ตั้งจาก `auth.uid()`/server ห้ามให้ caller ส่ง actor เอง
- **ห้าม grant anon EXECUTE บน RPC เขียนข้อมูล แบบไม่มี guard + ไม่มี rate-limit** — และจำไว้ว่า Postgres grant EXECUTE ให้ `PUBLIC` โดย default → ต้อง `revoke execute ... from public` ก่อน grant ให้ role ที่ตั้งใจ ถ้าจำเป็น (เช่น login-failure) ต้องใส่ guard ใน RPC จำกัด action/result/ขอบเขต เมื่อ `auth.uid() IS NULL`
- **ห้ามเก็บ secret/PII ใน log:** sanitize ตัด `password/token/secret/key` + mask/hash email และ identifier อ่อนไหว (NFR-009)
- **RPC ต้อง `SECURITY DEFINER` + `search_path=''` เสมอ** และอ้างชื่อเต็ม (`public.*`, `auth.*`)
- **Logging เป็น best-effort** (ไม่ทำ action หลักพัง) แต่ error ต้องเข้า monitoring/console ห้ามเงียบ
- **ทุก migration ที่แตะ RLS ต้องมี test ครอบ:** cross-workspace มองไม่เห็น + `anon SELECT = 0 แถว`
- **VERIFY ต้องรันจริงก่อนสรุป** (`lint`/`typecheck`/`test`/`build` + SQL harness) + `git diff` เช็ก secret

## บล็อกสรุปส่งฝั่งวางแผน (handoff block)
- หลังจบงานหรือรายงานสถานะที่เจ้าของต้องเอาไปวางในแชต "ฝั่งวางแผน" ให้สรุปเป็น **กล่องโค้ดเดียว** (คัดลอกง่ายในคลิกเดียว)
- **หัวข้อ / label เป็นภาษาอังกฤษ** (เช่น `Scope`, `Verify`, `Blocked`, `Status`, `Next`) แต่ **เนื้อหาเป็นภาษาไทย**
- เลือกความละเอียดตามงาน:
  - งาน/คำถามไม่ซับซ้อน → **แบบกระชับ (Concise)** — label + เนื้อไทยสั้น ๆ บรรทัดเดียวต่อหัวข้อ
  - งานซับซ้อน/ต้องเข้าใจตรงกันสูง → **แบบละเอียด (Detailed)** — bullet ครบ (Scope / Verify / Blocked / Status / Next)

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

## บทบาทและวิธีทำงานร่วมกัน (หัวหน้า / สมอง / ช่าง)
- **หัวหน้า** = เจ้าของโปรเจกต์ + ผู้อนุมัติขั้นสุดท้าย ทุกการเปลี่ยน scope/สถาปัตยกรรมต้องได้อนุมัติก่อน
- **สมอง** = ผู้วางแผน/ตรวจงาน (แชตฝั่งวางแผน) ออก handoff block เป็นคำสั่งงาน
- **ช่าง** = ผู้เขียนโค้ด (Claude Code = ไฟล์นี้) ทำงานตาม handoff ที่หัวหน้าอนุมัติแล้ว
- ก่อนลงมือทุกครั้ง: อ่าน CLAUDE.md (ไฟล์นี้) + PROGRESS.md ให้จบ ถ้าคำสั่งในแชตขัดกับไฟล์ ให้หยุดถามหัวหน้า

## Scope fidelity (ทำครบตามที่เคาะ — กันของหล่นเงียบ)
- ทำ **ครบทุกข้อใน scope ที่หัวหน้าเคาะ** ห้ามดรอป/เลื่อนข้อใดโดยไม่แจ้ง
- ถ้าทำข้อใดไม่ได้หรือเห็นควรเลื่อน → เขียนไว้ชัดในบล็อกสรุป หัวข้อ **`Dropped/Deferred`** พร้อมเหตุผล ให้หัวหน้าตัดสิน (ห้ามเงียบ)
- ห้ามสร้าง finding / severity / label ใหม่ขึ้นเอง (เช่นตั้งชื่อ "M4", "M-new" ที่ไม่มีในรายงาน Auditor) — ถ้าเจอปัญหาใหม่จริง ให้ออกเป็น finding เต็มรูป (ID·Evidence file:line·Severity) ใน audit report ก่อนเสนอ

## ความซื่อตรงของสถานะ / commit / audit
- commit message + คอมเมนต์โค้ด ต้อง **ตรงกับสิ่งที่ทำจริง** — ไม่เคลมเกิน ไม่ปิดบัง scope ที่ยังไม่ทำ (ถ้ามีข้อที่ยังไม่ทำ ให้ระบุใน commit body หรือบล็อกสรุป)
- ห้ามประกาศผลตรวจ (**Go / High=0 / severity**) โดยไม่มี **audit report ที่ commit จริงใน `audits/`** ที่ระบุ Head commit ที่ตรวจ + วันที่ + การนับ severity
- re-audit ต้องรันใน session แยก (independent reviewer) และ **commit report ไฟล์ใหม่** (ห้ามทับไฟล์ audit รอบก่อน)

## Migration (immutable หลัง commit)
- migration ที่ commit/push แล้ว = **ห้ามแก้ย้อน** → ต้องแก้เพิ่มด้วยไฟล์ใหม่ ไล่เลขต่อ (0007, 0008, ...)
- migration ใหม่ต้องมี test ครอบใน harness และถูกหยิบเข้า CI db-harness อัตโนมัติ (loop `ls 0*.sql`)

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
