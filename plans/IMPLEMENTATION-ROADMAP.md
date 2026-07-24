# Implementation Roadmap

## หลักการ

- หนึ่ง Phase ต้องส่งมอบของที่ทดลองใช้ได้
- Task ขนาด S/M เป็นหลัก
- ห้ามเริ่ม Phase ถัดไปเมื่อ Critical/High ของ Phase ปัจจุบันยังไม่มีแผนแก้
- ทุก Phase มี Demo, Test และ Retrospective

## Phase 0 — Repository and Engineering Foundation

### เป้าหมาย

สร้างโครงโปรเจ็กที่ Build/Test ได้และมี Module Convention

### Deliverables

- Project scaffold
- Environment validation
- Lint/Format/Type Check/Test/Build scripts
- CI ขั้นพื้นฐาน
- Error model และ Correlation ID
- Database migration foundation
- Auth placeholder หรือ Auth foundation
- Documentation structure

### Gate

- Clean install สำเร็จ
- Lint/Type Check/Test/Build ผ่าน
- ไม่มี Secret ใน Repository

## Phase 1 — Identity, Workspace and Channel Strategy

### Requirements

FR-001, FR-002, NFR-001, NFR-002, NFR-011

### Deliverables

- Login/Session
- Workspace/Membership/Role
- Channel Profile
- Audience, Pillar, Brand Rule
- Server authorization
- Audit Log

### Gate

- Workspace isolation test ผ่าน
- Permission matrix test ผ่าน

## Phase 2 — Character, Idea and Content Project

### Deliverables

- Character Bible + Version
- Idea Backlog + Scoring
- Convert Idea to Content Project
- Content Project State Machine
- Activity Timeline

### Gate

- Invalid Transition ถูกปฏิเสธ
- Concurrent update ไม่เขียนทับกันเงียบ ๆ

## Phase 3 — Brief and Script Studio

### Deliverables

- Format-specific Brief Template
- Script structure สำหรับ 4 Content Types
- Script Version/Revision
- Approval/Changes Requested
- Timing estimate

### Gate

- Approval ผูก Version
- แก้ Script หลัง Approve แล้วต้องเปิด Revision ใหม่

## Phase 4 — Storyboard, Scene and Prompt Library

### Deliverables

- Scene/Shot Editor
- Asset Dependency
- Prompt Template/Variable/Version
- Generate Prompt Pack
- Export Scene CSV/Markdown

### Gate

- Scene Duration Validation
- Prompt Pack reproducible จาก Version เดิม

## Phase 5 — Asset Library and Production Export

### Deliverables

- Upload/External Link
- Metadata/Tag/Search
- Provenance/Usage Note
- Parent/Derivative relation
- Production ZIP Export

### Gate

- Asset ที่ใช้ใน Approved Revision ลบถาวรไม่ได้
- Export Contract Test ผ่าน

## Phase 6 — Quality and Publish Readiness

### Deliverables

- QC Template Version
- QC Run/Finding/Evidence
- Content/Child/Copyright/Technical Check
- Gate Decision
- Metadata Package

### Gate

- Project ที่มี Blocking Finding ไป Publish ไม่ได้
- Approval และ QC อ้าง Revision เดียวกัน

## Phase 7 — Generation Provider Integration

### Deliverables

- Provider Adapter Interface
- Fake Adapter
- Text/Image/Voice Adapter อย่างน้อยประเภทละหนึ่งตัวตามทรัพยากร
- Job Queue, Retry, Timeout, Idempotency
- Cost Estimate/Actual

### Gate

- Provider Down ไม่ทำให้ Project Data เสีย
- Duplicate request ไม่สร้าง Job ซ้ำ
- Secret ไม่ออก Client/Log

## Phase 8 — Render and Editor Handoff

### Deliverables

- Timeline Manifest
- Render Adapter หรือ External Editor Package
- Caption/Audio/Aspect validation
- Render Job status

### Gate

- Missing Asset ถูกตรวจพบก่อน Render
- Retry Render ปลอดภัย

## Phase 9 — Publishing

### Deliverables

- Publish Queue
- Manual Export ก่อน
- Publishing Adapter ภายหลัง
- Scheduled/Published/Failed status
- Post-publish verification

### Gate

- Publish ได้เฉพาะ READY_TO_PUBLISH
- Idempotency ป้องกัน Upload ซ้ำ

## Phase 10 — Analytics and Learning Loop

### Deliverables

- Metrics import
- Dashboard ตาม Channel/Pillar/Format/Hook/Cost
- Experiment model
- Insight note และ Template recommendation

### Gate

- Metric ผูก Published Video และ Version ถูกต้อง
- Dashboard ไม่สรุปจากข้อมูลไม่ครบโดยไม่แจ้ง Warning

## Phase 11 — Hardening and Production

### Deliverables

- Security review
- Performance test
- Backup/Restore drill
- Alert/Monitoring
- Admin/User guide
- UAT
- Deployment/Rollback runbook

### Gate

- Critical = 0
- High = 0 หรือมี Risk Acceptance ชัดเจน
- UAT ผ่าน
- Restore test ผ่าน

## Backlog หลัง Production

- Collaboration comment/mention
- Prompt A/B experiment
- Advanced similarity/originality checks
- Multi-language localization
- Batch generation
- Mobile companion
- Template marketplace ภายใน Workspace
