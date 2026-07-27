# Quality Gates and Checklists

## Gate A — Requirement Ready

- [ ] Scope/Out of Scope ชัดเจน
- [ ] Requirement มี ID
- [ ] Acceptance Criteria ทดสอบได้
- [ ] Facts/Assumptions/Constraints แยกแล้ว
- [ ] Content Formats ระบุแล้ว
- [ ] Sensitive/Child-content risks ระบุแล้ว

## Gate B — Architecture Ready

- [ ] เลือก Modular Monolith
- [ ] Module Boundary ชัดเจน
- [ ] Provider Adapter Contract มีแล้ว
- [ ] State Machine มี Invalid Transition Rules
- [ ] Data Model มี Constraints/Indexes สำคัญ
- [ ] Secret/Storage/Queue/Backup Design มีแล้ว
- [ ] Architecture Decision บันทึกแล้ว

## Gate C — Task Ready

- [ ] Task ID และ Requirement IDs
- [ ] Scope Files/Modules
- [ ] Do Not Touch
- [ ] Acceptance Criteria
- [ ] Test Cases
- [ ] Security Consideration
- [ ] Migration/Rollback
- [ ] Definition of Done

## Gate D — Merge Ready

- [ ] Diff อยู่ใน Scope
- [ ] Format ผ่าน
- [ ] Lint ผ่าน
- [ ] Type Check ผ่าน
- [ ] Unit Test ผ่าน
- [ ] Integration Test ผ่านตามความเกี่ยวข้อง
- [ ] Build ผ่าน
- [ ] Permission/State Test ผ่าน
- [ ] ไม่มี Secret/PII ใน Diff/Log
- [ ] Documentation อัปเดต
- [ ] Claude Review ผ่านสำหรับ Milestone สำคัญ

## Gate E — Content Project Script Approval

- [ ] Brief Approved
- [ ] Script Version ชัดเจน
- [ ] Audience/Tone ตรง Channel
- [ ] Character Consistency
- [ ] Duration Estimate
- [ ] Language appropriate
- [ ] Originality/Reference Note
- [ ] Reviewer/Approved At บันทึก

## Gate F — Asset Approval

- [ ] Asset Source/Provider
- [ ] Prompt/Version
- [ ] Usage/License Note
- [ ] Character/Style Consistency
- [ ] Technical Specification
- [ ] No unintended text/logo/PII
- [ ] Approved/Rejected reason

## Gate G — Publish Readiness

- [ ] Approved Project Revision
- [ ] Final Render/Export Version
- [ ] Content QC ผ่าน
- [ ] Child-content Checklist ผ่าน
- [ ] Copyright/Provenance ผ่าน
- [ ] Technical QC ผ่าน
- [ ] Metadata/Thumbnail ตรงเนื้อหา
- [ ] ไม่มี Blocking Finding
- [ ] Owner/Reviewer Approval
- [ ] Rollback/Manual Recovery พร้อม

## Gate H — Production Release

- [ ] Environment Variables ครบ
- [ ] Production Secret Store พร้อม
- [ ] Migration ทดสอบ
- [ ] Rollback ทดสอบ
- [ ] Backup/Restore ทดสอบ
- [ ] Monitoring/Alert พร้อม
- [ ] Rate Limit/Timeout/Retry พร้อม
- [ ] UAT ผ่าน
- [ ] คู่มือผู้ใช้/ผู้ดูแลพร้อม
- [ ] Critical/High ปิดแล้ว

## Audit Severity Guide

| Severity | ตัวอย่าง |
|---|---|
| Critical | Workspace data leak, Secret leak, data loss, publish to wrong channel |
| High | Bypass QC/Approval, duplicate costly job, wrong version published |
| Medium | Broken UX state, slow query, incomplete observability, maintainability risk |
| Low | Naming, documentation clarity, minor technical debt |
