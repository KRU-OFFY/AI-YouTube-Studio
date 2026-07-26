// Sanitize audit metadata before it is stored (NFR-009: log ห้ามมี secret/PII).
// - ตัด key อ่อนไหว (password/token/secret/key/...) ทิ้ง
// - mask ค่า email (เก็บแบบ t***@domain แทน raw PII)

const SUBSTRING_SENSITIVE = [
  "password",
  "passwd",
  "token",
  "secret",
  "apikey",
  "api_key",
  "authorization",
  "cookie",
  "jwt",
  "credential",
  "private_key",
  "access_key",
];
const EXACT_SENSITIVE = new Set(["key", "pass", "auth", "pwd"]);

function isSensitiveKey(key: string): boolean {
  const k = key.toLowerCase();
  if (EXACT_SENSITIVE.has(k)) return true;
  return SUBSTRING_SENSITIVE.some((s) => k.includes(s));
}

// t***@gmail.com — ไม่เก็บ local-part เต็ม
export function maskEmail(email: string): string {
  const value = String(email).trim();
  const at = value.indexOf("@");
  if (at <= 0) return "***";
  const head = value.slice(0, 1);
  const domain = value.slice(at + 1);
  return `${head}***@${domain}`;
}

export function sanitizeMetadata(
  input: Record<string, unknown>,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(input ?? {})) {
    if (isSensitiveKey(k)) continue; // ตัดทิ้ง
    if (k.toLowerCase().includes("email") && typeof v === "string") {
      out[k] = maskEmail(v);
      continue;
    }
    out[k] = v;
  }
  return out;
}
