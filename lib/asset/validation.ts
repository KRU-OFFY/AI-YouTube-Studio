// Pure validation helpers for asset + rights forms (unit-testable, no DB/network).
// ⚠️ ASSET_TYPES / ASSET_ROLES ต้องตรงกับ enum ใน DB (0001 asset_type · 0010 asset_role)

export const ASSET_TITLE_MAX = 160;

export const ASSET_TYPES = ["image", "audio", "video", "text", "other"] as const;
export type AssetType = (typeof ASSET_TYPES)[number];

export const ASSET_ROLES = ["anchor", "scene", "song", "sfx", "narration"] as const;
export type AssetRole = (typeof ASSET_ROLES)[number];

export const TYPE_LABEL: Record<AssetType, string> = {
  image: "ภาพ",
  audio: "เสียง",
  video: "วิดีโอ",
  text: "ข้อความ",
  other: "อื่น ๆ",
};

export const ROLE_LABEL: Record<AssetRole, string> = {
  anchor: "แองเคอร์ (ตัวหลัก reuse)",
  scene: "ฉาก",
  song: "เพลง",
  sfx: "เอฟเฟกต์เสียง",
  narration: "เสียงบรรยาย",
};

export function isAssetType(v: string): v is AssetType {
  return (ASSET_TYPES as readonly string[]).includes(v);
}

export function isAssetRole(v: string): v is AssetRole {
  return (ASSET_ROLES as readonly string[]).includes(v);
}

export function validateAssetTitle(title: string): string | null {
  const v = title.trim();
  if (v.length > ASSET_TITLE_MAX)
    return `ชื่อ asset ต้องไม่เกิน ${ASSET_TITLE_MAX} ตัวอักษร`;
  return null;
}

// storage_path (path หรือ external URL) — ห้ามว่าง (column NOT NULL)
export function validateStoragePath(path: string): string | null {
  if (!path.trim()) return "กรุณากรอกที่อยู่ไฟล์ (path หรือ URL)";
  return null;
}

// rights ห้ามว่าง: tool_used + exported_at required (ตาม handoff)
export function validateRights(input: {
  toolUsed: string;
  exportedAt: string;
}): string | null {
  if (!input.toolUsed.trim()) return "กรุณากรอกเครื่องมือที่ใช้ (tool_used) — rights ห้ามว่าง";
  if (!input.exportedAt.trim()) return "กรุณากรอกวันที่ส่งออก (exported_at)";
  const t = Date.parse(input.exportedAt);
  if (Number.isNaN(t)) return "รูปแบบวันที่ exported_at ไม่ถูกต้อง";
  return null;
}
