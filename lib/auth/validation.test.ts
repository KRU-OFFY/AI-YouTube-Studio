import { describe, it, expect } from "vitest";
import {
  validateEmail,
  validatePassword,
  validateCredentials,
  PASSWORD_MIN_LENGTH,
} from "./validation";

describe("validateEmail", () => {
  it("ผ่านเมื่ออีเมลถูกรูปแบบ", () => {
    expect(validateEmail("toffy@puifun.com")).toBeNull();
  });

  it("ตัดช่องว่างหัวท้ายก่อนตรวจ", () => {
    expect(validateEmail("  toffy@puifun.com  ")).toBeNull();
  });

  it("แจ้ง error เมื่อเว้นว่าง", () => {
    expect(validateEmail("")).toBe("กรุณากรอกอีเมล");
  });

  it.each(["toffy", "toffy@", "toffy@puifun", "@puifun.com", "a b@c.com"])(
    "แจ้ง error เมื่อรูปแบบผิด: %s",
    (bad) => {
      expect(validateEmail(bad)).toBe("รูปแบบอีเมลไม่ถูกต้อง");
    },
  );
});

describe("validatePassword", () => {
  it("ผ่านเมื่อรหัสผ่านยาวพอ", () => {
    expect(validatePassword("supersecret")).toBeNull();
  });

  it("ผ่านที่ความยาวขั้นต่ำพอดี", () => {
    expect(validatePassword("a".repeat(PASSWORD_MIN_LENGTH))).toBeNull();
  });

  it("แจ้ง error เมื่อเว้นว่าง", () => {
    expect(validatePassword("")).toBe("กรุณากรอกรหัสผ่าน");
  });

  it("แจ้ง error เมื่อสั้นเกินไป", () => {
    expect(validatePassword("a".repeat(PASSWORD_MIN_LENGTH - 1))).toBe(
      `รหัสผ่านต้องมีอย่างน้อย ${PASSWORD_MIN_LENGTH} ตัวอักษร`,
    );
  });
});

describe("validateCredentials", () => {
  it("คืน null เมื่อทั้งคู่ถูกต้อง", () => {
    expect(validateCredentials("toffy@puifun.com", "supersecret")).toBeNull();
  });

  it("คืน error ของอีเมลก่อนเมื่ออีเมลผิด", () => {
    expect(validateCredentials("bad", "short")).toBe("รูปแบบอีเมลไม่ถูกต้อง");
  });

  it("คืน error ของรหัสผ่านเมื่ออีเมลถูกแต่รหัสผ่านสั้น", () => {
    expect(validateCredentials("toffy@puifun.com", "short")).toBe(
      `รหัสผ่านต้องมีอย่างน้อย ${PASSWORD_MIN_LENGTH} ตัวอักษร`,
    );
  });
});
