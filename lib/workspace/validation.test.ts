import { describe, it, expect } from "vitest";
import {
  validateWorkspaceName,
  normalizeTimezone,
  normalizeCurrency,
  WORKSPACE_NAME_MAX,
} from "./validation";

describe("validateWorkspaceName", () => {
  it("ผ่านเมื่อชื่อปกติ", () => {
    expect(validateWorkspaceName("Puifun Studio")).toBeNull();
  });

  it("ตัดช่องว่างหัวท้าย", () => {
    expect(validateWorkspaceName("  Puifun  ")).toBeNull();
  });

  it("แจ้ง error เมื่อว่าง", () => {
    expect(validateWorkspaceName("   ")).toBe("กรุณากรอกชื่อ workspace");
  });

  it("แจ้ง error เมื่อยาวเกินกำหนด", () => {
    expect(validateWorkspaceName("a".repeat(WORKSPACE_NAME_MAX + 1))).toBe(
      `ชื่อ workspace ต้องไม่เกิน ${WORKSPACE_NAME_MAX} ตัวอักษร`,
    );
  });

  it("ผ่านที่ความยาวสูงสุดพอดี", () => {
    expect(validateWorkspaceName("a".repeat(WORKSPACE_NAME_MAX))).toBeNull();
  });
});

describe("normalizeTimezone", () => {
  it("คืนค่าเดิมเมื่อมีค่า", () => {
    expect(normalizeTimezone("Asia/Tokyo")).toBe("Asia/Tokyo");
  });
  it("คืน default เมื่อว่าง", () => {
    expect(normalizeTimezone("   ")).toBe("Asia/Bangkok");
  });
});

describe("normalizeCurrency", () => {
  it("แปลงเป็นตัวพิมพ์ใหญ่", () => {
    expect(normalizeCurrency("usd")).toBe("USD");
  });
  it("คืน default เมื่อว่าง", () => {
    expect(normalizeCurrency("")).toBe("THB");
  });
});
