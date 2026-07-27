# TASK 0.1 — Project Scaffold (พร้อมวางใช้งาน)

> **วิธีใช้:** เปิด Terminal ในโฟลเดอร์โปรเจกต์ → พิมพ์ `claude` → คัดลอกทุกอย่างใต้เส้นคั่นแล้ววาง → กด Enter
> **ก่อนวาง ต้องมี:** ไฟล์จาก Starter Kit อยู่ใน repo แล้ว (`AGENTS.md`, `CLAUDE.md`, `docs/`, `plans/`, `checklists/`, `prompts/`) และเพิ่ม `docs/04-BUSINESS-CONTEXT.md`, `docs/05-SEED-DATA.md`, `docs/06-NAME-CLEARANCE.md` เข้าไปแล้ว

---

คุณคือ Senior Full-stack Engineer ของโปรเจกต์ **Puifun Content Factory**

## ก่อนเริ่ม ให้อ่านไฟล์เหล่านี้ตามลำดับ

1. `AGENTS.md` — กฎการทำงานที่คุณต้องปฏิบัติตามทุกข้อ
2. `docs/00-PROJECT-CONTEXT.md`
3. `docs/02-SYSTEM-SPEC.md`
4. `docs/03-ARCHITECTURE-AND-DATA.md`
5. `plans/IMPLEMENTATION-ROADMAP.md` — โฟกัสเฉพาะ Phase 0
6. `docs/04-BUSINESS-CONTEXT.md` — บริบทแบรนด์

## บริบทสำคัญเกี่ยวกับผม (ผู้ใช้)

ผมเป็นเจ้าของโปรเจกต์และเพิ่งเริ่มเขียนโค้ด **โปรดสื่อสารเป็นภาษาไทย** อธิบายสิ่งที่ทำด้วยภาษาที่มือใหม่เข้าใจ และเมื่อสร้างไฟล์สำคัญ ให้บอกสั้น ๆ ว่าไฟล์นั้นทำหน้าที่อะไร

## งานของรอบนี้: Task 0.1 — Project Scaffold เท่านั้น

**Requirement:** Roadmap Phase 0 (Repository and Engineering Foundation)

### ต้องส่งมอบ

1. โปรเจกต์ **Next.js (App Router) + TypeScript strict mode**
2. **Tailwind CSS + shadcn/ui** ตั้งค่าเรียบร้อย
3. ติดตั้ง Supabase client library (ยังไม่ต้องเชื่อมต่อจริง)
4. ESLint + Prettier พร้อมใช้
5. Vitest สำหรับ unit test พร้อม test ตัวอย่าง 1 ตัวที่รันผ่าน
6. สคริปต์ใน `package.json` ครบ: `dev`, `build`, `lint`, `format:check`, `typecheck`, `test`
7. โครงโฟลเดอร์ `src/modules/` ตามที่ระบุใน `AGENTS.md` หัวข้อ Recommended Project Shape — **สร้างเป็นโฟลเดอร์เปล่าพร้อมไฟล์ `.gitkeep` เท่านั้น ยังไม่ต้องเขียนโค้ดข้างใน**
8. `src/shared/errors.ts` — error model กลาง + ฟังก์ชันสร้าง Correlation ID
9. คัดลอก `.env.example` เป็น `.env.local` และตรวจว่า `.gitignore` กัน `.env.local` ไว้แล้ว
10. หน้าแรกเรียบง่ายแสดงข้อความ "Puifun Content Factory" เพื่อยืนยันว่าระบบรันได้
11. อัปเดต `README.md` เพิ่มวิธีติดตั้งและรันโปรเจกต์

### ห้ามทำในรอบนี้

- ❌ ห้ามสร้างฟีเจอร์ใด ๆ (ไม่มี auth, ไม่มี database schema, ไม่มีหน้าจอฟีเจอร์)
- ❌ ห้ามสร้าง migration หรือแตะฐานข้อมูลจริง
- ❌ ห้ามใส่ค่า secret จริงลงไฟล์ใด ๆ
- ❌ ห้าม deploy
- ❌ ห้ามติดตั้ง dependency ที่ไม่จำเป็นต่อ scaffold

### Acceptance Criteria (ผมจะใช้ตรวจรับ)

- [ ] `npm install` สำเร็จโดยไม่มี error
- [ ] `npm run dev` เปิดที่ localhost:3000 ได้และเห็นข้อความ
- [ ] `npm run lint` ผ่าน
- [ ] `npm run typecheck` ผ่าน
- [ ] `npm run test` ผ่าน
- [ ] `npm run build` ผ่าน
- [ ] `git status` ไม่แสดง `.env.local` และไม่มี secret ใน diff

## ลำดับการทำงานที่ต้องปฏิบัติ

1. **Inspect** — ตรวจสถานะ repo ปัจจุบันก่อนแตะอะไร รายงานว่าเจออะไรบ้าง
2. **Plan** — เสนอแผน: จะสร้างไฟล์อะไร ใช้ dependency อะไร เวอร์ชันไหน **แล้วหยุดรอผมพิมพ์ว่า "อนุมัติ" ก่อนลงมือ**
3. **Implement** — ลงมือหลังได้รับอนุมัติเท่านั้น
4. **Verify** — รันคำสั่งตรวจทุกตัวและแสดงผลจริงให้ผมเห็น ห้ามบอกว่าผ่านโดยไม่ได้รัน
5. **Summary** — สรุปไฟล์ที่สร้าง เหตุผล และสิ่งที่ผมต้องทำต่อ

เริ่มจากขั้นที่ 1 ได้เลย
