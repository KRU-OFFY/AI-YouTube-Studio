// Pure validation helpers for workspace forms (unit-testable, no DB/network).
// Return null = valid; return a Thai error message = invalid.

export const WORKSPACE_NAME_MAX = 80;

export function validateWorkspaceName(name: string): string | null {
  const value = name.trim();
  if (!value) return "กรุณากรอกชื่อ workspace";
  if (value.length > WORKSPACE_NAME_MAX)
    return `ชื่อ workspace ต้องไม่เกิน ${WORKSPACE_NAME_MAX} ตัวอักษร`;
  return null;
}

// timezone / currency มีค่า default เสมอ — คืนค่าที่ปลอดภัยเมื่อว่าง
export function normalizeTimezone(tz: string): string {
  return tz.trim() || "Asia/Bangkok";
}

export function normalizeCurrency(currency: string): string {
  return currency.trim().toUpperCase() || "THB";
}
