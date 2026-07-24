# TOFFY AI YouTube Studio

ระบบไปป์ไลน์ผลิตคอนเทนต์ด้วย AI สำหรับช่อง YouTube เด็กภาษาไทยแบรนด์ **ปุยฝัน (Puifun)**
Stack: **Next.js (App Router) + TypeScript + Supabase** (เตรียม deploy บน Vercel)

> อ่านสถานะงานล่าสุดที่ [`PROGRESS.md`](./PROGRESS.md) ก่อนเริ่มทำงานต่อทุกครั้ง
> ถ้าใช้ Claude Code — บริบท / กติกาโปรเจกต์อยู่ที่ [`CLAUDE.md`](./CLAUDE.md)

## Requirements
- Node.js 20+ (แนะนำ 22)
- npm 10+
- โปรเจกต์ Supabase (ฟรีทีเออก็พอสำหรับ dev)

## Setup

```bash
# 1) ติดตั้ง dependencies
npm install

# 2) เตรียม env
cp .env.example .env.local
# แล้วเปิด .env.local แก้ค่าจริงจาก Supabase Dashboard → Project Settings → API

# 3) รัน dev server
npm run dev
# → http://localhost:3000
```

หน้า `/dashboard` จะแสดงสถานะการเชื่อมต่อ Supabase — ถ้าเชื่อมสำเร็จจะเห็นแถบเขียว

## Supabase migrations

ไฟล์ SQL เริ่มต้นอยู่ที่ `supabase/migrations/0001_init.sql`
เลือกวิธีรันได้ 2 ทาง:

- **แบบเร็ว:** copy เนื้อหาไฟล์ไปวางใน Supabase Dashboard → SQL Editor → Run
- **แบบใช้ CLI:** `supabase link --project-ref <ref>` แล้ว `supabase db push`

## Project structure

```
app/                หน้า Next.js (App Router)
  dashboard/        placeholder แดชบอร์ด + health check ของ Supabase
components/         (ยังว่าง) UI components ที่ใช้ซ้ำ
lib/
  supabase/         Supabase client — แยกฝั่ง browser / server / admin
supabase/
  migrations/       ไฟล์ SQL migration
docs/
  QC-checklist.md   เช็กลิสต์ QC ก่อนอัปโหลดตอนใหม่
CLAUDE.md           บริบทและกติกาให้ Claude Code
PROGRESS.md         สถานะงาน / ขั้นตอนถัดไป
```

## Scripts

```bash
npm run dev        # dev server
npm run build      # build production
npm run start      # start production build
npm run lint       # eslint
npm run typecheck  # tsc --noEmit
```

## Security note
- **ห้าม** commit ไฟล์ `.env` หรือ `.env.local` เด็ดขาด (อยู่ใน `.gitignore` แล้ว)
- `SUPABASE_SERVICE_ROLE_KEY` ใช้เฉพาะฝั่ง server เท่านั้น ห้ามหลุดถึง browser
