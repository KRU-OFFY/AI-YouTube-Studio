# Prompt สำหรับทำงานราย Task

## 1. Prompt วางแผน Task

```text
วิเคราะห์ Task ต่อไปนี้โดยยังไม่แก้ไฟล์

Task ID: [ID]
Task Name: [ชื่อ]
Requirement IDs: [FR/NFR]
Goal: [เป้าหมาย]
Acceptance Criteria:
- [ข้อ 1]
- [ข้อ 2]

ดำเนินการ
1. ตรวจ Source of Truth และไฟล์ที่เกี่ยวข้อง
2. ระบุ Current Behavior
3. ระบุไฟล์ที่คาดว่าต้องแก้
4. ระบุ Dependency และ Risk
5. เสนอ Test Cases: Happy/Error/Permission/Edge
6. ระบุ Migration และ Rollback
7. สร้างแผนย่อยไม่เกิน 7 ขั้น

ห้ามแก้ไฟล์ในรอบนี้
```

## 2. Prompt ให้ Codex ลงมือพัฒนา

```text
ผู้ใช้อนุมัติ Task นี้แล้ว

Task ID: [ID]
Requirement IDs: [IDs]
Scope Files/Modules:
- [path]

Do Not Touch:
- [path]

Acceptance Criteria:
- [ข้อ]

Required Tests:
- [test/command]

Rollback:
- [วิธี]

ให้ทำงานตามลำดับ
1. ตรวจ Git Status/Branch
2. อ่านไฟล์ใน Scope
3. เพิ่มหรือปรับ Test
4. Implement เฉพาะ Scope
5. รัน Targeted Test
6. รัน Regression/Lint/Type Check/Build
7. ตรวจ Diff และ Secret
8. อัปเดตเอกสาร
9. สรุปผลแล้วหยุด

หากต้องขยาย Scope ให้บันทึก Change Request ห้ามแก้เอง
```

## 3. Prompt ให้ Claude ตรวจ Task

```text
ตรวจ Task [ID] แบบ Read-only

เปรียบเทียบ
- Requirement/Acceptance Criteria
- Source of Truth
- Git Diff
- Test Results

ตรวจ
- Scope
- Logic/State
- Version/Approval
- Authorization/Validation
- Data Integrity
- Error/Retry/Idempotency
- Audit/Log Redaction
- Test Gap
- Rollback

รายงาน Pass/Conditional Pass/Fail พร้อม Finding ที่มี Evidence
ห้ามแก้ไฟล์
```

## 4. Prompt แก้ Finding

```text
แก้ Finding ต่อไปนี้เพียงข้อเดียว

Finding ID: [ID]
Severity: [ระดับ]
Evidence: [file/line/function]
Expected: [พฤติกรรมที่ต้องการ]
Actual: [พฤติกรรมปัจจุบัน]
Approved Fix: [แนวทาง]
Test to Add: [รายการ]
Allowed Scope: [paths]
Rollback: [วิธี]

ทำ Test-first หรือ Test-alongside จำกัด Diff และรายงาน Verification ทุกคำสั่ง
```

## 5. Prompt สร้างโมดูลใหม่

```text
สร้างโมดูล [ชื่อโมดูล] ตาม Module Boundary ใน Architecture

Responsibilities:
- [รายการ]

Inputs/Outputs:
- [รายการ]

Dependencies ที่อนุญาต:
- [รายการ]

Dependencies ที่ห้าม:
- [รายการ]

Requirements:
- [IDs]

ให้สร้าง
1. Domain types/policies
2. Application use cases
3. Repository/provider interfaces
4. Infrastructure adapters เท่าที่จำเป็น
5. API/UI boundary
6. Unit/Integration tests
7. Documentation

ห้ามสร้าง Generic Abstraction ที่ยังไม่มีการใช้จริง
```

## 6. Prompt สร้าง Provider Adapter

```text
เพิ่ม Provider Adapter: [ชื่อ]
ประเภท: [text/image/voice/music/video/publishing]

ใช้ Interface กลางจาก Architecture ห้ามเรียก SDK จาก UI หรือ Domain

ต้องรองรับ
- Input validation
- Cost estimate เมื่อทำได้
- Submit/Poll หรือ Sync result
- Timeout
- Rate limit
- Retry classification
- Idempotency
- Cancellation เมื่อ Provider รองรับ
- Error normalization
- Redacted logging
- Mock/Fake adapter สำหรับ Test

Secret ใช้ Server-only Environment/Secret Store
เพิ่ม Contract Test และ Provider Failure Test
```

## 7. Prompt สร้าง Workflow Content Format

```text
เพิ่ม Content Format: [นิทานเด็ก/การ์ตูน/เพลง/Shorts/อื่น]

กำหนด
- Brief Template
- Script Structure
- Scene Rules
- Prompt Pack Types
- Duration Rules
- QC Checklist Additions
- Metadata Template
- Analytics Dimensions

รักษา Core Content Project State เดิม และเพิ่มเฉพาะ Policy/Template ที่แตกต่าง
เพิ่ม Test ว่า Format ใหม่ไม่ทำให้ Format เดิมเปลี่ยนพฤติกรรม
```

## 8. Prompt Release Readiness

```text
ทำ Release Readiness Review แบบ Read-only

ตรวจ
- Requirement Coverage
- Migration/Rollback
- Environment Variables
- Secrets
- Lint/Type Check/Test/Build
- Security
- File Upload
- Queue/Retry/Idempotency
- Backup/Restore
- Monitoring/Alert
- UAT Evidence
- User/Admin Guide

สรุป Go / Conditional Go / No-Go พร้อม Blocking Items
ห้าม Deploy
```
