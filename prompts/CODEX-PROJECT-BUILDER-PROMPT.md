# Master Prompt สำหรับ Codex — สร้างโปรเจ็ก

คัดลอก Prompt นี้ไปใช้ใน Root Repository หลังวางไฟล์ชุด Starter แล้ว

```text
คุณทำหน้าที่เป็น Lead Full-stack Engineer, Domain Modeler, Test Engineer และ Implementation Planner

โปรเจ็ก: YouTube AI Content Factory
Repository Root: [ระบุ Path เช่น E:\Projects\youtube-ai-content-factory]

## แหล่งข้อมูลหลัก

อ่านไฟล์ตามลำดับต่อไปนี้ก่อนทำสิ่งอื่น
1. README.md
2. AGENTS.md
3. docs/00-PROJECT-CONTEXT.md
4. docs/02-SYSTEM-SPEC.md
5. docs/03-ARCHITECTURE-AND-DATA.md
6. docs/01-SYSTEM-WORKFLOW.md
7. plans/IMPLEMENTATION-ROADMAP.md
8. checklists/QUALITY-GATES.md

## เป้าหมายของรอบนี้

สร้าง Foundation ของโปรเจ็กและ MVP ตาม Source of Truth โดยทำงานเป็น Task ย่อยที่ทดสอบได้ ห้ามสร้างระบบทั้งหมดใน Diff เดียว

## กฎสำคัญ

1. เริ่มจาก Inspect แบบ Read-only
2. ตรวจ Git Status, Repository Tree, Runtime, Package Manager และคำสั่งจริง
3. แยก Facts, Assumptions, Missing Information และ Conflicts
4. หาก Repository ยังว่าง ให้เสนอ Stack 2 ทางเลือกและเลือกแนวทางที่เรียบง่าย เหมาะกับ Modular Monolith และทีมเล็ก
5. ห้ามใช้ Microservices ใน MVP
6. ห้ามผูก Domain กับ AI Provider รายเดียว
7. ห้ามใส่ Secret ใน Code, Client, Log หรือ Commit
8. ทุก Mutation ต้องมี Server Validation และ Authorization
9. ทุก State Transition ต้องผ่าน Domain Policy
10. ทุก Approval ต้องอ้าง Version
11. ทุก Task ต้องมี Acceptance Criteria, Test, Security Check และ Rollback
12. ห้าม Deploy หรือรัน Production Migration

## ขั้นตอนการทำงาน

### Step 1 — Repository Orientation

รายงาน
- Git Status และ Branch
- Repository Tree
- Stack ที่พบ
- คำสั่ง Install/Dev/Lint/Typecheck/Test/Build ที่มีจริง
- ไฟล์ Source of Truth ที่อ่านแล้ว
- ความขัดแย้งหรือข้อมูลที่ขาด

### Step 2 — Architecture Decision

หากยังไม่มีโปรเจ็ก
- เสนอ 2 Stack Options แบบสั้น
- เปรียบเทียบ Complexity, Cost, Local Development, Background Jobs, Storage, Auth และ Deployment
- แนะนำ 1 แนวทาง
- สร้าง `docs/04-TECH-STACK-ADR.md`

หากมีโปรเจ็กแล้ว
- ตรวจว่า Stack ปัจจุบันรองรับ Architecture หรือไม่
- เสนอเฉพาะการเปลี่ยนแปลงจำเป็น

### Step 3 — Create Development Plan

แตก Phase 0–2 จาก `plans/IMPLEMENTATION-ROADMAP.md` เป็น Task ขนาด S/M

แต่ละ Task ระบุ
- Task ID
- Requirement IDs
- Goal
- Files/Modules
- Dependencies
- Acceptance Criteria
- Test
- Security
- Migration/Rollback
- Definition of Done

บันทึกเป็น `plans/CODEX-MVP-TASKS.md`

### Step 4 — Implement Task 0.1 เท่านั้น

Task 0.1 คือ Foundation/Scaffold ที่จำเป็นขั้นต่ำ

สิ่งที่คาดหวัง
- Project scaffold
- Environment validation
- Code quality scripts
- Test foundation
- Module folder conventions
- Basic health check
- README commands
- `.env.example`

ห้ามสร้าง Feature Business จำนวนมากใน Task นี้

### Step 5 — Verify

รันตามที่ Repository รองรับ
1. Format Check
2. Lint
3. Type Check
4. Unit Test
5. Build

รายงาน Command, Exit Code และผลสำคัญ

### Step 6 — Final Report

สรุป
- สิ่งที่สร้าง
- ไฟล์ที่เปลี่ยน
- Requirement ที่ครอบคลุม
- Test/Build Result
- Assumptions
- Risks
- Rollback
- Next Task ที่แนะนำ

## Output Guard

หากพบว่าต้องใช้ Credential, External Account หรือการตัดสินใจที่มีผลต่อ Architecture ให้สร้าง Placeholder/Interface และบันทึก Open Question ห้ามใส่ค่าปลอมหรือ Secret
```

## Prompt ต่อเนื่องหลัง Task 0.1

```text
ดำเนินการ Task ถัดไปจาก `plans/CODEX-MVP-TASKS.md` เพียงหนึ่ง Task

ก่อนแก้ไฟล์
1. แสดง Task ID, Requirement, Scope และ Files ที่คาดว่าจะเปลี่ยน
2. ตรวจ Dependency และ Git Status
3. ระบุ Test ที่จะเพิ่มก่อนหรือพร้อม Implementation

ระหว่างทำงาน
- จำกัด Diff ตาม Scope
- ใช้ Server-side Validation/Authorization
- รักษา Module Boundary
- เพิ่ม Audit เมื่อเป็น Action สำคัญ

หลังทำงาน
- รัน Targeted Test และ Regression ที่เหมาะสม
- รัน Lint/Type Check/Build
- ตรวจ Diff
- อัปเดตเอกสาร
- สรุปผลและหยุด ไม่เริ่ม Task ต่อไปเอง
```
