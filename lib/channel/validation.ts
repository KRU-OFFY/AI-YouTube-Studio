// Pure validation helpers for channel forms (unit-testable, no DB/network).
// Return null = valid; return a Thai error message = invalid.

export const CHANNEL_NAME_MAX = 80;
const SLUG_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export function validateChannelName(name: string): string | null {
  const value = name.trim();
  if (!value) return "กรุณากรอกชื่อ channel";
  if (value.length > CHANNEL_NAME_MAX)
    return `ชื่อ channel ต้องไม่เกิน ${CHANNEL_NAME_MAX} ตัวอักษร`;
  return null;
}

export function validateSlug(slug: string): string | null {
  const value = slug.trim();
  if (!value) return "กรุณากรอก slug";
  if (!SLUG_RE.test(value))
    return "slug ใช้ได้เฉพาะ a-z, 0-9 และ - (เช่น puifun)";
  return null;
}

// สร้าง slug อัตโนมัติจากข้อความ (fallback ให้ผู้ใช้แก้ได้)
export function slugify(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
