# Project Context — YouTube AI Content Factory

## 1. ชื่อโครงการชั่วคราว

**YouTube AI Content Factory**  
ชื่อภาษาไทย: **ระบบโรงงานคอนเทนต์ YouTube ด้วย AI**

ชื่อเป็น Working Name สามารถเปลี่ยนภายหลังโดยไม่กระทบโครงสร้างระบบ

## 2. วิสัยทัศน์

สร้างระบบที่ช่วยผู้สร้างคอนเทนต์คนเดียวหรือทีมขนาดเล็ก วางแผน ผลิต ตรวจคุณภาพ เผยแพร่ และเรียนรู้จากผลลัพธ์ของคอนเทนต์ YouTube ได้อย่างเป็นระบบ ลดงานซ้ำ รักษาความสม่ำเสมอของแบรนด์ และควบคุมความเสี่ยงด้านเนื้อหา ลิขสิทธิ์ และต้นทุน AI

## 3. ปัญหาที่ระบบต้องแก้

1. ข้อมูลแนวคิด สคริปต์ Prompt และ Asset กระจัดกระจายหลายเครื่องมือ
2. ตัวละคร ภาพ เสียง โทน และเรื่องราวไม่สม่ำเสมอระหว่างตอน
3. ใช้เวลามากในการแปลงแนวคิดเป็น Script, Storyboard, Scene List และ Prompt
4. ไม่ทราบสถานะของวิดีโอแต่ละชิ้นและงานที่ติดค้าง
5. ขาดขั้นตอนตรวจคุณภาพและความเสี่ยงก่อนเผยแพร่
6. ไม่เห็นต้นทุนต่อวิดีโอและผลตอบแทนของแต่ละรูปแบบคอนเทนต์
7. ผล Analytics ไม่ถูกนำกลับมาปรับ Content Strategy และ Prompt อย่างเป็นระบบ

## 4. กลุ่มคอนเทนต์หลัก

### 4.1 นิทานเด็ก

- นิทานก่อนนอน
- นิทานคุณธรรม
- นิทานเสริมทักษะชีวิต
- นิทานผจญภัยแบบตอนต่อเนื่อง
- นิทานเพื่อการเรียนรู้ระดับประถม

### 4.2 การ์ตูนสำหรับเด็ก

- การ์ตูนสั้นแบบมีบทเรียน
- การ์ตูนตัวละครประจำช่อง
- การ์ตูนสถานการณ์ปัญหาและการแก้ปัญหา
- การ์ตูนเรียนรู้คำศัพท์ ตัวเลข วิทยาศาสตร์ หรือทักษะดิจิทัล

### 4.3 เพลงจาก AI

- เพลงเด็ก
- เพลงช่วยจำเนื้อหาการเรียน
- เพลงนิทานและเพลงตัวละคร
- เพลงประกอบคลิปและ Background Music ที่มีหลักฐานสิทธิ์ใช้งาน

### 4.4 การ์ตูนคลิปสั้นและ Shorts

- มุกหรือสถานการณ์สั้น
- Mini Story 15–60 วินาที
- Fact/Quiz/Challenge แบบตัวละคร
- Teaser จากวิดีโอยาว
- ตอนสั้นต่อเนื่องเพื่อพาผู้ชมไปยัง Playlist

## 5. ขอบเขตระบบ

### In Scope

- Workspace และ Channel Profile
- Brand Bible และ Character Bible
- Content Pillar, Audience, Tone และ Production Rules
- Idea Backlog และ Content Calendar
- Content Brief, Script, Storyboard และ Scene Plan
- Prompt Template และ Prompt Versioning
- Asset Library และสิทธิ์การใช้งาน
- AI Generation Job สำหรับข้อความ ภาพ เสียง เพลง และวิดีโอผ่าน Adapter
- Production Package สำหรับนำไปตัดต่อภายนอกหรือ Render ภายในระบบ
- Quality Control และ Policy Checklist แบบปรับแก้ได้
- Thumbnail/Title/Description/Tag Package
- Publishing Queue และการเชื่อม YouTube แบบ Phase ภายหลัง
- Analytics Import, Experiment และ Learning Loop
- Cost Tracking, Audit Log, Error Log และ Retry

### Out of Scope ระยะแรก

- ระบบรีวิวสินค้าและ Affiliate
- ระบบซื้อโฆษณา
- Social Network เต็มรูปแบบ
- Marketplace ซื้อขาย Prompt หรือ Asset
- ระบบสร้างโมเดล AI เอง
- การเผยแพร่อัตโนมัติแบบไม่มีผู้อนุมัติ
- Microservices จำนวนมากโดยไม่มีเหตุผลด้าน Scale

## 6. ผู้ใช้และบทบาท

| Role | หน้าที่ |
|---|---|
| Owner | เจ้าของ Workspace อนุมัติงบ ระบบ และการเผยแพร่ |
| Content Strategist | กำหนดกลุ่มเป้าหมาย Pillar Format และ Calendar |
| Scriptwriter | สร้างและแก้ Script, Dialogue และ Narration |
| Creative Producer | ดูแล Storyboard, Scene, Character และ Asset |
| Editor | ประกอบเสียง ภาพ วิดีโอ Caption และ Render |
| Reviewer | ตรวจเนื้อหาเด็ก คุณภาพ ลิขสิทธิ์ และ Publish Readiness |
| Analyst | วิเคราะห์ผลวิดีโอ ทดลอง Hook, Thumbnail และ Format |
| Admin | จัดการผู้ใช้ Provider, Secret, Quota และ Audit |

สำหรับการใช้งานคนเดียว Owner สามารถถือทุกบทบาท แต่ระบบยังต้องบันทึกว่าขั้นตอนไหนได้รับการอนุมัติแล้ว

## 7. หลักการออกแบบ

1. **Human approval before publish**
2. **Provider-agnostic** — เปลี่ยนบริการ AI ได้ผ่าน Adapter
3. **Source traceability** — ทุก Asset ระบุที่มา Prompt รุ่น และสิทธิ์
4. **Reusable IP** — Character Bible, World Bible และ Style Guide ใช้ซ้ำได้
5. **Small reversible steps** — ทุก Task ย้อนกลับได้
6. **Content safety by design** — ตรวจคำต้องห้าม ความเหมาะสม และความเสี่ยงก่อนผลิต
7. **Cost visibility** — รู้ต้นทุนต่อ Generation, Scene และ Video
8. **Analytics feedback loop** — ผลจริงต้องย้อนกลับสู่ Template และ Strategy
9. **Thai-first, multilingual-ready**
10. **Mobile-responsive creator workflow**

## 8. สมมติฐานที่ใช้ในการออกแบบ

- ผู้ใช้หลักเริ่มจากเจ้าของช่องหรือทีมขนาดเล็ก
- ระบบรองรับหลายช่อง แต่ควรแยก Brand Profile ตามช่อง
- แต่ละช่องควรมี Content Pillar และ Audience ชัดเจน
- การสร้างสื่อด้วย AI บางส่วนอาจทำภายนอกระบบในระยะแรก
- ระบบต้องเก็บผลลัพธ์ทั้งไฟล์จริงและ Link/Reference ไปยังบริการภายนอก
- นโยบายแพลตฟอร์มสามารถเปลี่ยนได้ จึงใช้ Checklist แบบ Configurable แทนการ Hard-code
- ไม่เก็บ API Secret ในฐานข้อมูลทั่วไปหรือฝั่ง Client

## 9. ตัวชี้วัดความสำเร็จของระบบ

### Product Metrics

- เวลาเฉลี่ยจาก Idea → Approved Script
- เวลาเฉลี่ยจาก Approved Script → Publish Ready
- อัตรางานผ่าน QC ในรอบแรก
- จำนวน Asset ที่นำกลับมาใช้ซ้ำ
- จำนวนข้อผิดพลาดจาก Character/Style Inconsistency
- ต้นทุนเฉลี่ยต่อวิดีโอ
- อัตรา Generation Job สำเร็จและ Retry

### Content Metrics

- Click-through rate ของ Thumbnail/Title
- Average view duration และ Retention ตามช่วงเวลา
- Completion rate ของ Shorts
- จำนวนผู้ชมกลับมาดูซ้ำ
- Subscriber conversion ต่อวิดีโอ
- Performance แยกตาม Content Pillar, Format, Hook และ Character

## 10. Source of Truth

- Requirement และขอบเขต: `docs/02-SYSTEM-SPEC.md`
- Workflow และ State: `docs/01-SYSTEM-WORKFLOW.md`
- Architecture และ Data: `docs/03-ARCHITECTURE-AND-DATA.md`
- แผนพัฒนา: `plans/IMPLEMENTATION-ROADMAP.md`
- กฎ Codex: `AGENTS.md`
- กฎ Claude Code: `CLAUDE.md`
