// Pure validation helpers for auth forms.
// Return null = valid; return a Thai error message = invalid.
// Kept side-effect free so they can be unit-tested without a DB or network.

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const PASSWORD_MIN_LENGTH = 8;

export function validateEmail(email: string): string | null {
  const value = email.trim();
  if (!value) return "กรุณากรอกอีเมล";
  if (!EMAIL_RE.test(value)) return "รูปแบบอีเมลไม่ถูกต้อง";
  return null;
}

export function validatePassword(password: string): string | null {
  if (!password) return "กรุณากรอกรหัสผ่าน";
  if (password.length < PASSWORD_MIN_LENGTH)
    return `รหัสผ่านต้องมีอย่างน้อย ${PASSWORD_MIN_LENGTH} ตัวอักษร`;
  return null;
}

// รวม validate ฟอร์มทั้งชุด คืน error ข้อความแรกที่พบ (หรือ null ถ้าผ่าน)
export function validateCredentials(
  email: string,
  password: string,
): string | null {
  return validateEmail(email) ?? validatePassword(password);
}
