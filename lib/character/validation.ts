// Pure validation helpers for character forms (unit-testable, no DB/network).
// mirror DB: character_type enum (0011) · slug pattern เดียวกับ channel

export const CHARACTER_NAME_MAX = 80;
const SLUG_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export const CHARACTER_TYPES = ["character", "brand_motif"] as const;
export type CharacterType = (typeof CHARACTER_TYPES)[number];

export const TYPE_LABEL: Record<CharacterType, string> = {
  character: "ตัวละคร",
  brand_motif: "brand motif (ไม่พูด)",
};

// pillar code advisory (appears_in) — ตรงกับ description P1/P2/P3 ใน pillars
export const PILLAR_CODES = ["P1", "P2", "P3"] as const;
export type PillarCode = (typeof PILLAR_CODES)[number];

export function isCharacterType(v: string): v is CharacterType {
  return (CHARACTER_TYPES as readonly string[]).includes(v);
}

export function validateCharacterName(name: string): string | null {
  const v = name.trim();
  if (!v) return "กรุณากรอกชื่อตัวละคร";
  if (v.length > CHARACTER_NAME_MAX)
    return `ชื่อต้องไม่เกิน ${CHARACTER_NAME_MAX} ตัวอักษร`;
  return null;
}

export function validateSlug(slug: string): string | null {
  const v = slug.trim();
  if (!v) return "กรุณากรอก slug";
  if (!SLUG_RE.test(v)) return "slug ใช้ได้เฉพาะ a-z, 0-9 และ - (เช่น nong-pui)";
  return null;
}

// JSON field (appearance/voice) — ว่าง = {} · ต้อง parse ได้ + เป็น object
export function validateJsonObject(raw: string): string | null {
  const v = raw.trim();
  if (!v) return null;
  try {
    const parsed = JSON.parse(v);
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed))
      return "ต้องเป็น JSON object (เช่น {\"tone\":\"นุ่มนวล\"})";
    return null;
  } catch {
    return "รูปแบบ JSON ไม่ถูกต้อง";
  }
}

// แปลง textarea (บรรทัด/คอมมา) → text[]
export function toArray(raw: string): string[] {
  return raw
    .split(/[\n,]/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}
