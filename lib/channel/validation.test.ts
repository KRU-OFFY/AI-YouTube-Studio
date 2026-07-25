import { describe, it, expect } from "vitest";
import {
  validateChannelName,
  validateSlug,
  slugify,
  CHANNEL_NAME_MAX,
} from "./validation";

describe("validateChannelName", () => {
  it("ผ่านเมื่อชื่อปกติ", () => {
    expect(validateChannelName("ปุยฝัน")).toBeNull();
  });
  it("แจ้ง error เมื่อว่าง", () => {
    expect(validateChannelName("  ")).toBe("กรุณากรอกชื่อ channel");
  });
  it("แจ้ง error เมื่อยาวเกิน", () => {
    expect(validateChannelName("a".repeat(CHANNEL_NAME_MAX + 1))).toBe(
      `ชื่อ channel ต้องไม่เกิน ${CHANNEL_NAME_MAX} ตัวอักษร`,
    );
  });
});

describe("validateSlug", () => {
  it("ผ่านเมื่อ slug ถูกรูปแบบ", () => {
    expect(validateSlug("puifun")).toBeNull();
    expect(validateSlug("puifun-kids-2")).toBeNull();
  });
  it("แจ้ง error เมื่อว่าง", () => {
    expect(validateSlug("")).toBe("กรุณากรอก slug");
  });
  it.each(["Puifun", "pui fun", "pui_fun", "-puifun", "puifun-", "ปุยฝัน"])(
    "แจ้ง error เมื่อรูปแบบผิด: %s",
    (bad) => {
      expect(validateSlug(bad)).toBe(
        "slug ใช้ได้เฉพาะ a-z, 0-9 และ - (เช่น puifun)",
      );
    },
  );
});

describe("slugify", () => {
  it("แปลงข้อความเป็น slug", () => {
    expect(slugify("Puifun Kids Channel")).toBe("puifun-kids-channel");
  });
  it("ตัด - หัวท้าย", () => {
    expect(slugify("  Hello!! ")).toBe("hello");
  });
});
