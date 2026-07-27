# 05 — Seed Data (ข้อมูลตั้งต้นของระบบ)

> ข้อมูลชุดนี้คือ "ข้อมูลจริงชุดแรก" ที่ต้องอยู่ในระบบหลังจบ Sprint 2
> ใช้ทดสอบว่าระบบทำงานกับงานจริงได้ ไม่ใช่แค่ข้อมูลหลอก
> อ้างอิงบริบทจาก `04-BUSINESS-CONTEXT.md`
>
> **หมายเหตุ (Claude Code):** ข้อมูลในไฟล์นี้ถูกแปลงเป็น SQL แล้วที่ `supabase/seed.sql`
> ครอบคลุมตาราง `content_pillars`, `characters`, `episodes` (ตาม schema migration 0001)
> ส่วน Workspace / Channel / Audience Profile ยังไม่มีตารางรองรับ — ดู "ช่องว่าง schema" ใน `PROGRESS.md`

---

## 1. Workspace

| ฟิลด์ | ค่า |
|---|---|
| name | Puifun Studio |
| default_language | th |
| timezone | Asia/Bangkok |
| currency | THB |

## 2. Channel

| ฟิลด์ | ค่า |
|---|---|
| name | ปุยฝัน |
| slug | puifun |
| handle | @puifun |
| primary_language | th |
| made_for_kids_default | **true** |
| audience_age_range | 2–5 |
| secondary_audience | 6–9 (ปิดไว้ก่อน) |
| tone_of_voice | อบอุ่น ช้า นุ่มนวล ไม่กระตุ้น |
| visual_style | 2D/2.5D พาสเทล ขอบมน ไม่มีเส้นคม |
| publishing_cadence | Long-form 1/สัปดาห์ + Shorts 3/สัปดาห์ |
| forbidden_elements | ความรุนแรง, ตัวร้าย, ตัวหนังสือในภาพ, มนุษย์, เสียงดังตกใจ, การตัดภาพถี่ |

## 3. Audience Profile

| ฟิลด์ | ค่า |
|---|---|
| primary_viewer | เด็ก 2–5 ปี |
| decision_maker | พ่อแม่/ผู้ปกครอง (เป็นคนกดเล่น) |
| viewing_context | ก่อนนอน, ระหว่างกินข้าว, ในรถ |
| parent_need | คอนเทนต์ที่ทำให้เด็กสงบลง ไม่ใช่ตื่นเต้นขึ้น |
| avoid | สีจัดกระตุก, เสียงแหลม, ตัดภาพเร็ว, CTA เร่งเร้า |

## 4. Content Pillars

| code | name | format | target_duration | kpi |
|---|---|---|---|---|
| P1 | นิทานก่อนนอนสอนใจ | long_form | 4–7 นาที | rewatch rate, retention 30 วิ |
| P2 | เพลง sing-along | long_form | 2–4 นาที | completion rate, rewatch |
| P3 | มุกสั้น/ทายอะไรเอ่ย | shorts | 15–40 วิ | views, subs per 1,000 views |

## 5. Characters (Character Bible ชุดแรก)

### 5.1 น้องปุย
```yaml
name: น้องปุย
role: ตัวเอก / ตัวแทนเด็กผู้ชม
species: ก้อนปุย
appearance:
  shape: กลม นุ่ม ไม่มีแขนขาชัดเจน มีติ่งปุยเล็ก ๆ แทนมือ
  color_primary: "#FFFFFF ขาวนวล"
  color_accent: "#FFD3DD แก้มชมพูอ่อน"
  eyes: กลมโต สีน้ำตาลเข้ม มีประกายจุดเดียว
  size_reference: เท่าลูกฟุตบอล
personality: [ขี้สงสัย, ใจดี, ตื่นเต้นง่าย, ไม่เคยโกรธ]
voice:
  age_impression: เด็ก 4 ขวบ
  pace: ช้า
  tone: ใส สดใส
  emotion_range: [สงสัย, ดีใจ, กลัวนิดหน่อย, อบอุ่น]
forbidden: [ห้ามร้องไห้เสียงดัง, ห้ามโกรธ, ห้ามมีแขนขาแบบมนุษย์]
canonical_prompt: >
  a small round fluffy white puff creature, soft cream-white fur,
  large round dark brown eyes with single highlight, soft pink cheeks,
  tiny puff nubs instead of arms, no mouth teeth, pastel storybook
  illustration, soft rounded edges, gentle lighting, no text
appears_in: [P1, P2, P3]   # ต้องมีทุกตอน
```

### 5.2 มุ่ย
```yaml
name: มุ่ย
role: พี่ / ผู้ให้คำตอบและปลอบใจ
species: เม่นน้อย (ขนนุ่มไม่แหลม)
appearance:
  color_primary: "#C89B7B น้ำตาลอ่อน"
  quills: ขนนุ่มมนเหมือนปุยขนแกะ ไม่แหลมคม
  eyes: เรียวอ่อนโยน
  accessory: ผ้าพันคอสีเขียวมิ้นต์
personality: [รอบคอบ, อ่อนโยน, ชอบดูแล, พูดช้า]
voice:
  age_impression: เด็ก 7 ขวบ
  tone: นุ่มนวล อบอุ่น
forbidden: [ห้ามทำหน้าขนแหลมน่ากลัว, ห้ามดุน้องปุย]
canonical_prompt: >
  a small gentle hedgehog with soft rounded fluffy quills (not sharp),
  light warm brown fur, mint green scarf, kind narrow eyes,
  pastel storybook illustration, soft rounded edges, no text
appears_in: [P1, P2, P3]
```

### 5.3 กัปตันโก๊ะ
```yaml
name: กัปตันโก๊ะ
role: ตัวสร้างเสียงหัวเราะ / สะพานสู่กลุ่ม 6–9 ปี
species: กบเขียวตัวเล็ก
appearance:
  color_primary: "#9BD46A เขียวอ่อน"
  accessory: หมวกใบไม้
  expression: ยิ้มกว้าง คิ้วขยับเยอะ
personality: [จอมกวน, พลังงานสูง, ซุ่มซ่าม, ใจดี]
voice:
  tone: การ์ตูนกวน จังหวะเร็ว
forbidden: [ห้ามปรากฏในนิทานก่อนนอน (P1), ห้ามแกล้งจนเพื่อนเสียใจ]
canonical_prompt: >
  a tiny cheerful green frog wearing a small leaf hat, big smile,
  expressive eyebrows, pastel storybook illustration,
  soft rounded edges, no text
appears_in: [P2, P3]
```

### 5.4 ดาวดวงน้อย (motif — ไม่ใช่ตัวละครพูดได้)
```yaml
name: ดาวดวงน้อย
type: brand_motif
usage: ปิดท้ายนิทานก่อนนอนทุกตอน (signature shot)
appearance: ดาวห้าแฉกสีเหลืองนวล เรืองแสงนุ่ม ลอยลงมาห่มผ้าให้ตัวละคร
dialogue: none
canonical_prompt: >
  a small soft glowing pale yellow five-point star, warm gentle light,
  floating down, pastel night sky background, no text
```

---

## 6. Idea Backlog ชุดแรก (10 ไอเดีย Pilot)

| # | ชื่อเรื่อง | Pillar | Format | คะแนนตั้งต้น (Demand/Originality/Reuse/Cost) |
|---|---|---|---|---|
| 1 | เพลงธีม "สวัสดีทุ่งปุยฝัน" | P2 | Long-form | 5/5/5/2 |
| 2 | นิทาน "ปุยของหนูหายไปไหน" (ความกล้าหาญ) | P1 | Long-form | 5/4/4/3 |
| 3 | เพลง ก-ฮ ฉบับทุ่งปุยฝัน | P2 | Long-form | 5/3/5/3 |
| 4 | นิทาน "มุ่ยแบ่งขนมให้น้องปุย" (การแบ่งปัน) | P1 | Long-form | 4/4/4/3 |
| 5 | เพลงนับเลข 1–10 กับก้อนปุยลอย | P2 | Long-form | 5/3/5/2 |
| 6 | "กัปตันโก๊ะกระโดดพลาด" | P3 | Shorts | 4/4/3/1 |
| 7 | "ทายเสียงสัตว์ในทุ่ง" | P3 | Shorts | 4/3/4/1 |
| 8 | "หลับฝันดีนะ" คลิปสงบ 30 วิ | P3 | Shorts | 3/5/5/1 |
| 9 | "หน้าตลก ๆ ของน้องปุย" | P3 | Shorts | 4/4/3/1 |
| 10 | นิทาน "คืนที่ดาวหล่นลงมา" (ความกลัวมืด) | P1 | Long-form | 5/5/4/3 |

> **ลำดับผลิต Pilot:** #1 → #2 → #3 แล้วตัด Shorts #6, #8, #9 จากสามตอนแรก

---

## 7. QC Checklist Template ชุดแรก

| หมวด | รายการตรวจ | Blocking? |
|---|---|---|
| Child Safety | ตั้ง Made for Kids = true | ✅ ใช่ |
| Child Safety | ไม่มีคำต้องห้ามตาม forbidden word list | ✅ ใช่ |
| Child Safety | ไม่มีเสียงดังตกใจ / สีกระตุก | ✅ ใช่ |
| Originality | มี originality_note ระบุว่าตอนนี้ต่างจากตอนก่อนอย่างไร | ✅ ใช่ |
| Originality | ผ่าน human rewrite แล้ว (ไม่ใช่ AI output ดิบ) | ✅ ใช่ |
| Rights | Asset ทุกชิ้นมี Rights Record ครบ | ✅ ใช่ |
| Rights | ไม่มีการเลียนเสียงบุคคลจริง | ✅ ใช่ |
| Continuity | ตัวละครหน้าตา/สี/สัดส่วนตรง Character Bible | ✅ ใช่ |
| Continuity | ไม่เกิน 2 ตัวละครหลักต่อเฟรม | ⚠️ เตือน |
| Continuity | ไม่มีตัวหนังสือ/โลโก้ในภาพ | ✅ ใช่ |
| Technical | Subtitle ตรงเสียงจริง | ✅ ใช่ |
| Technical | Thumbnail อ่านออกบนมือถือ มี focal point เดียว | ⚠️ เตือน |
| Technical | ความยาวตรงเป้าของ Pillar | ⚠️ เตือน |
| Brand | กัปตันโก๊ะไม่ปรากฏใน P1 | ⚠️ เตือน |
| Brand | นิทาน P1 จบด้วย signature shot ดาวดวงน้อย | ⚠️ เตือน |

---

## 8. Forbidden Word List (configurable)

```
ตาย, ฆ่า, ผี, น่ากลัว, โง่, อ้วน, ขี้เหร่, เกลียด, ซื้อเลย, กดสั่ง, ราคาพิเศษ
```
