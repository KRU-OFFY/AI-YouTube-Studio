# 07 — Architecture Decision Record (Sprint 1)

> บันทึกการตัดสินใจสถาปัตยกรรมที่ฝ่ายวางแผนตัดสิน เพื่อตอบคำถามจาก Claude Code หลัง PR #1
> วันที่: 24 ก.ค. 2026 | สถานะ: อนุมัติแล้ว | ผู้ตัดสิน: Architect (ฝั่งวางแผน)

---

## ADR-001 — workspace/channel เป็นตารางจริง ไม่ใช่ config

**บริบท:** seed data อ้างถึง Workspace และ Channel แต่ schema ยังไม่มีตารางรองรับ Claude Code ถามว่าจะเพิ่มตารางหรือถือเป็น config คงที่

**ตัดสิน:** เป็น **ตารางจริงพร้อม RLS** ตาม Task 1.2 (workspaces + workspace_members) และ Task 1.3 (channels)

**เหตุผล:**
- FR-002 กำหนด multi-tenancy ผ่าน workspace + RLS — config คงที่ทำไม่ได้
- channel มี state (draft/approved) และมี Gate 0 — ต้องเป็น row ที่เปลี่ยนสถานะได้
- ระบบต้องรองรับหลาย channel ในอนาคต (แม้ตอนนี้มี 1)

**ผลกระทบ:** ห้ามสร้างตารางเปล่าไม่มี RLS แล้วเติมทีหลัง — RLS ต้องมาพร้อมตารางตั้งแต่ migration แรกของมัน

---

## ADR-002 — forbidden_words เป็นตาราง / QC checklist คง docs ก่อน

**บริบท:** ทั้งสองถูกนิยามใน docs Claude Code ถามว่าเก็บเป็นตาราง config หรือคงเป็นไฟล์

**ตัดสิน:**
- `forbidden_words`: **ตาราง config (channel-scoped) ทำได้เลย** seed จาก docs/05
- QC checklist template: **คง docs ไปก่อน** สร้างตารางตอน Sprint 6

**เหตุผล:**
- forbidden_words เป็น flat list เล็ก ถูก query เพื่อ validate ในหลายจุด → เป็นตารางคุ้มค่าตั้งแต่ต้น
- QC checklist มี versioning + โครงสร้างซับซ้อน (ตาม T6.1) → สร้างตอนถึงเฟส หลีกเลี่ยง over-engineering ล่วงหน้า (YAGNI)

**หลักการ:** ปลายทางของทั้งคู่คือตารางในระบบ ไม่ใช่ docs ถาวร — docs เป็นเพียง source ชั่วคราวจนกว่าจะ seed เข้าตาราง เพื่อไม่ให้ข้อมูลแตกสองที่พร้อมกัน

---

## ADR-003 — ยึดชื่อตาราง `rights_records`

**บริบท:** scaffold ใช้ `rights_log` แต่ handoff/แผนใช้ `rights_records` ชนกัน

**ตัดสิน:** ยึด **`rights_records`** — แก้ scaffold ให้ตรง

**เหตุผล:**
- ความสัมพันธ์จริงคือ 1 asset มี 1 ระเบียนสิทธิ์/provenance → "record" ตรงความหมาย
- `_log` สื่อ append-only event stream ซึ่งไม่ตรงกับโครงสร้างนี้

**ผลกระทบ:** เพิ่มกฎ naming ลง AGENTS.md — ชื่อตารางเป็นพหูพจน์ สื่อความหมายชัด (`characters`, `episodes`, `rights_records`, `audit_logs`)

---

## ADR-004 — ลำดับ dependency ราก→ยอด (เบรก Episodes UI)

**บริบท:** Claude Code เสนอทำ Episodes UI อ่านจากตาราง episodes ที่ seed แล้ว แต่ seed ทำก่อน auth/workspace/channel

**ตัดสิน:** **ยังไม่ทำ Episodes UI** จัดลำดับใหม่ราก→ยอดก่อน

**ลำดับที่ถูกต้อง:**
1. Task 1.1 — Auth
2. Task 1.2 — workspaces + workspace_members + RLS
3. Task 1.3 — channels (FK → workspace) + Gate 0 + RLS
4. ปรับ seed — workspace "Puifun Studio" + channel "ปุยฝัน" เป็น seed row → pillars/characters/episodes ผูก FK เข้า channel_id (channel → workspace)
5. Task 1.4 — audit log
6. Auditor ตรวจจบ Sprint 1
7. **จากนั้น** Episodes UI (เฟสถัดไป)

**เหตุผล:**
- episodes ต้องผูก channel → workspace → owner จึงบังคับ RLS ได้ ถ้าทำ UI บน flat schema ตอนนี้ ต้องรื้อ RLS ยัด ownership ทีหลัง = หนี้เทคนิค
- การวางรากให้ถูกทำให้ Episodes UI ในเฟสถัดไปได้ ownership/RLS ถูกตั้งแต่เกิด ไม่ต้องแก้ย้อน

**Foreign key ที่ต้องมี:**
```
workspace_members.workspace_id → workspaces.id
channels.workspace_id          → workspaces.id
pillars.channel_id             → channels.id
characters.channel_id          → channels.id
episodes.channel_id            → channels.id
episodes.pillar_id             → pillars.id
```

**Scope ของแต่ละ entity:** pillars / characters / episodes ทั้งหมดเป็น **channel-scoped** (เป็นของแบรนด์/ช่อง) เพราะโมเดล "Franchise เดียวต่อ channel"
