import { describe, it, expect } from "vitest";
import { sanitizeMetadata, maskEmail } from "./sanitize";

describe("maskEmail", () => {
  it("mask local-part เหลือตัวแรก", () => {
    expect(maskEmail("toffy@gmail.com")).toBe("t***@gmail.com");
  });
  it("คืน *** เมื่อไม่ใช่อีเมล", () => {
    expect(maskEmail("not-an-email")).toBe("***");
  });
});

describe("sanitizeMetadata", () => {
  it("ตัด key อ่อนไหวออก", () => {
    const out = sanitizeMetadata({
      name: "Puifun",
      password: "supersecret",
      token: "abc",
      secret: "x",
      key: "y",
      api_key: "z",
      authorization: "Bearer t",
    });
    expect(out).toEqual({ name: "Puifun" });
  });

  it("mask ค่า email", () => {
    expect(sanitizeMetadata({ email: "toffy@gmail.com" })).toEqual({
      email: "t***@gmail.com",
    });
  });

  it("เก็บ field ปลอดภัยตามเดิม", () => {
    expect(sanitizeMetadata({ slug: "puifun", count: 3 })).toEqual({
      slug: "puifun",
      count: 3,
    });
  });

  it("ไม่พังเมื่อ input ว่าง", () => {
    expect(sanitizeMetadata({})).toEqual({});
  });
});
