# System Specification

## 1. เป้าหมาย MVP

MVP ต้องช่วยผู้ใช้สร้าง **Production Package ที่พร้อมผลิตวิดีโอ** ได้ครบตั้งแต่ Channel Profile ถึง QC โดยยังทำงานได้แม้ไม่ได้เชื่อม AI Provider ทุกตัว

### MVP Must Have

1. Authentication และ Workspace แบบพื้นฐาน
2. Channel Profile, Brand Bible และ Character Bible
3. Idea Backlog และ Content Calendar
4. Content Project พร้อม State Machine
5. Content Brief, Script Revision และ Approval
6. Storyboard/Scene Plan
7. Prompt Template และ Prompt Pack
8. Asset Register พร้อม Provenance/License Note
9. QC Checklist และ Publish Readiness Gate
10. Export Production Package เป็น Markdown/JSON/ZIP
11. Audit Log สำคัญ
12. Responsive UI และ Error/Empty/Loading States

### MVP Should Have

- Cost Estimate แบบกรอกเองหรือคำนวณจาก Provider Config
- Generation Job แบบ Manual/External Link
- Import Asset จากไฟล์หรือ URL
- Dashboard สถานะงาน
- Duplicate/Similarity Warning ระดับพื้นฐาน

### หลัง MVP

- AI Provider Adapters
- Background Queue
- Automated Render
- YouTube Upload/Scheduling
- Analytics Sync
- Experiment Dashboard
- Team Collaboration ขั้นสูง

## 2. Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|---|---|---:|---|
| FR-001 | ผู้ใช้สร้าง Workspace ได้ | Must | สร้าง อ่าน แก้ชื่อ และกำหนด Timezone ได้ |
| FR-002 | ผู้ใช้สร้าง Channel Profile ได้หลายช่อง | Must | แต่ละช่องมี Audience, Pillar, Tone และ Rule แยกกัน |
| FR-003 | ระบบจัดการ Character Bible | Must | เก็บรูปลักษณ์ บุคลิก Voice Rule สี และ Reference Asset ได้ |
| FR-004 | ระบบจัดการ Idea Backlog | Must | สร้าง ให้คะแนน จัด Priority และแปลงเป็น Project ได้ |
| FR-005 | ระบบสร้าง Content Brief | Must | Template เปลี่ยนตาม Format และบันทึก Version ได้ |
| FR-006 | ระบบจัดการ Script Revision/Approval | Must | Approval ผูกกับ Version และเก็บ Change Summary |
| FR-007 | ระบบแปลง Script เป็น Scene Plan | Must | Scene มี Duration, Visual, Audio และ Asset Dependency |
| FR-008 | ระบบสร้าง Prompt Pack | Must | สร้าง Prompt ตาม Scene/Asset Type และบันทึก Template Version |
| FR-009 | ระบบจัดการ Asset Provenance | Must | Asset มี Source, Usage Note, Prompt และ Status |
| FR-010 | ระบบควบคุม State Transition | Must | ปฏิเสธ Invalid Transition ฝั่ง Server |
| FR-011 | ระบบ QC Checklist | Must | Checklist มี Version, Result, Reviewer และ Evidence |
| FR-012 | ระบบ Export Production Package | Must | Export Script, Scene, Prompt, Asset List, QC เป็นไฟล์เดียว |
| FR-013 | ระบบบันทึก Audit Log | Must | เก็บเหตุการณ์สำคัญโดยไม่เก็บ Secret |
| FR-014 | ระบบ Generation Job | Should | สร้าง Job, Retry, Cancel และบันทึก Output/Error ได้ |
| FR-015 | ระบบ Cost Tracking | Should | บันทึก Estimate/Actual แยก Provider และ Project |
| FR-016 | ระบบ Publish Queue | Later | เผยแพร่ได้เฉพาะ Project ที่ผ่าน Gate |
| FR-017 | ระบบ Analytics Import | Later | ผูก Metric กับ Video, Channel, Pillar และ Experiment |

## 3. Non-functional Requirements

| ID | Requirement | เกณฑ์ |
|---|---|---|
| NFR-001 | Security | Authorization บังคับใช้ฝั่ง Server ทุก Mutation |
| NFR-002 | Secret Management | Secret อยู่ใน Environment/Secret Store เท่านั้น |
| NFR-003 | Reliability | Job รองรับ Retry, Timeout และ Idempotency |
| NFR-004 | Auditability | Action สำคัญระบุ Actor, Time, Entity และ Result |
| NFR-005 | Maintainability | Module Boundary ชัด ไม่มี Provider Logic กระจายใน UI |
| NFR-006 | Portability | Export ข้อมูลสำคัญเป็น JSON/Markdown ได้ |
| NFR-007 | Accessibility | Keyboard, Label, Focus, Contrast และ Error Message เหมาะสม |
| NFR-008 | Responsiveness | ใช้งานได้บน Desktop/Tablet/Mobile |
| NFR-009 | Observability | Error มี Correlation ID และ Log ที่ไม่เปิดเผยข้อมูลสำคัญ |
| NFR-010 | Performance | หน้า Dashboard/Project ไม่ดึง Asset Binary ทั้งหมดโดยไม่จำเป็น |
| NFR-011 | Data Integrity | ใช้ Constraint/Transaction กับ State และ Approval สำคัญ |
| NFR-012 | Localization | แยก UI String และรองรับ Thai/English ในอนาคต |

## 4. โมดูลระบบ

### M01 Identity and Workspace

หน้าที่: Login, Session, Workspace, Membership, Role

### M02 Channel Strategy

หน้าที่: Channel Profile, Audience, Content Pillar, Brand Rule, Calendar Rule

### M03 Character and World Bible

หน้าที่: Character, Voice, Visual Rule, Relationship, Location, Prop, Style Reference

### M04 Idea and Calendar

หน้าที่: Idea Capture, Scoring, Priority, Calendar, Series

### M05 Content Project

หน้าที่: Project State, Brief, Revision, Approval, Activity Timeline

### M06 Script Studio

หน้าที่: Script Template, Section, Dialogue, Narration, Timing, Versioning

### M07 Storyboard and Scene

หน้าที่: Scene, Shot, Duration, Prompt Input, Asset Dependency

### M08 Prompt Library

หน้าที่: Template, Variable, Version, Provider Preset, Prompt Run Record

### M09 Asset Library

หน้าที่: Upload/Link, Metadata, Tag, Provenance, Rights, Approval, Derivative Chain

### M10 Generation Orchestrator

หน้าที่: Provider Adapter, Job Queue, Retry, Error, Cost, Output

### M11 Render and Export

หน้าที่: Timeline Package, Render Job, Production ZIP, External Editor Handoff

### M12 Quality and Compliance

หน้าที่: Checklist Template, Checklist Run, Finding, Evidence, Gate Decision

### M13 Publishing

หน้าที่: Metadata Package, Schedule, Upload, Status, Video Link

### M14 Analytics and Experiments

หน้าที่: Metric Import, Insight, Experiment, Recommendation

### M15 Settings and Operations

หน้าที่: Provider Config, Quota, Notification, Audit, Backup, Feature Flag

## 5. User Stories สำคัญ

### US-001 สร้างโปรไฟล์ช่อง

ในฐานะ Owner ฉันต้องการกำหนดกลุ่มเป้าหมาย โทน ภาพ และข้อห้ามของช่อง เพื่อให้ทุกคอนเทนต์สอดคล้องกัน

### US-002 สร้าง Character Bible

ในฐานะ Creative Producer ฉันต้องการบันทึกลักษณะตัวละครและ Reference เพื่อให้ภาพหลายตอนมีความต่อเนื่อง

### US-003 แปลงไอเดียเป็น Production Package

ในฐานะ Creator ฉันต้องการแปลง Idea เป็น Brief, Script, Scene และ Prompt Pack เพื่อเริ่มผลิตได้โดยไม่จัดเอกสารใหม่หลายรอบ

### US-004 ตรวจและอนุมัติ

ในฐานะ Reviewer ฉันต้องการเห็น Version, Evidence และ QC Finding เพื่ออนุมัติหรือขอแก้ไขอย่างมีเหตุผล

### US-005 วิเคราะห์ผล

ในฐานะ Analyst ฉันต้องการเปรียบเทียบผลตาม Pillar, Hook, Format และ Cost เพื่อเลือกสิ่งที่ควรทำซ้ำ

## 6. Acceptance Criteria ระดับระบบ

- ผู้ใช้สร้าง Channel → Idea → Brief → Script → Scene → Prompt Pack → QC → Export ได้ครบ
- ทุกขั้นสำคัญมี State และ Audit Log
- Server ป้องกันการข้าม Approval Gate
- Export Package เปิดอ่านได้โดยไม่ต้องใช้ระบบ
- Asset แสดง Source และ Usage Note
- Error จาก Provider ไม่ทำให้ข้อมูล Project สูญหาย
- ไม่มี Secret ส่งกลับ Client หรือปรากฏใน Log
- Test ครอบคลุม State Transition, Permission, Export และ QC Gate

## 7. Error Handling

### Validation Error

- แสดงข้อความเฉพาะฟิลด์
- ไม่ลบข้อมูลที่ผู้ใช้กรอก
- API ตอบ Error Code มาตรฐาน

### Provider Error

- แยก Timeout, Rate Limit, Invalid Request, Safety Rejection และ Provider Down
- บันทึก Error แบบ Redacted
- เสนอ Retry เมื่อปลอดภัย
- ไม่คิดว่า Job สำเร็จหากไม่มี Output ที่ตรวจสอบได้

### Partial Failure

- ใช้ Transaction เมื่อเปลี่ยน State/Approval
- Asset ที่สร้างสำเร็จแล้วไม่ถูกลบเพราะ Asset อื่นล้มเหลว
- Project แสดงสถานะ `PARTIAL` หรือรายการที่ต้องดำเนินการต่อ

## 8. Permission Matrix แบบย่อ

| Action | Owner | Strategist | Writer | Producer | Editor | Reviewer | Analyst | Admin |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Manage Workspace | ✓ |  |  |  |  |  |  | ✓ |
| Manage Channel | ✓ | ✓ |  |  |  | View | View | ✓ |
| Create Idea | ✓ | ✓ | ✓ | ✓ |  |  | ✓ |  |
| Edit Script | ✓ | ✓ | ✓ | View |  | Comment | View |  |
| Approve Script | ✓ |  |  |  |  | ✓ |  |  |
| Manage Asset | ✓ |  |  | ✓ | ✓ | Review | View |  |
| Approve QC | ✓ |  |  |  |  | ✓ |  |  |
| Publish | ✓ |  |  |  |  | Approve |  |  |
| View Analytics | ✓ | ✓ | View | View | View | View | ✓ |  |
| Manage Provider Secret |  |  |  |  |  |  |  | ✓ |

## 9. Definition of Done ต่อ Feature

- Requirement และ Acceptance Criteria อัปเดต
- UX States ครบ: Loading/Empty/Error/Success/Disabled
- Server Validation และ Authorization ครบ
- Unit/Integration Test ผ่าน
- Lint/Type Check/Build ผ่าน
- Migration และ Rollback ระบุชัด
- Log ไม่เปิดเผย Secret/PII
- เอกสารและตัวอย่างใช้งานอัปเดต
- Diff ไม่มีการเปลี่ยนนอก Scope
