import { describe, it, expect } from "vitest";
import {
  isCharacterType,
  validateCharacterName,
  validateSlug,
  validateJsonObject,
  toArray,
  CHARACTER_TYPES,
} from "./validation";

describe("character type guard (mirror DB enum)", () => {
  it("ค่า enum จริง → true", () => {
    for (const t of CHARACTER_TYPES) expect(isCharacterType(t)).toBe(true);
  });
  it("ค่ามั่ว → false", () => {
    expect(isCharacterType("villain")).toBe(false);
  });
});

describe("validateCharacterName", () => {
  it("ว่าง → error", () => expect(validateCharacterName("  ")).not.toBeNull());
  it("ยาวเกิน → error", () => expect(validateCharacterName("x".repeat(81))).not.toBeNull());
  it("ปกติ → null", () => expect(validateCharacterName("น้องปุย")).toBeNull());
});

describe("validateSlug", () => {
  it("ว่าง → error", () => expect(validateSlug("")).not.toBeNull());
  it("อักขระผิด → error", () => expect(validateSlug("Nong Pui")).not.toBeNull());
  it("ถูก → null", () => expect(validateSlug("nong-pui")).toBeNull());
});

describe("validateJsonObject", () => {
  it("ว่าง → null (default {})", () => expect(validateJsonObject("")).toBeNull());
  it("object → null", () => expect(validateJsonObject('{"tone":"นุ่ม"}')).toBeNull());
  it("array → error", () => expect(validateJsonObject("[1,2]")).not.toBeNull());
  it("JSON พัง → error", () => expect(validateJsonObject("{bad")).not.toBeNull());
});

describe("toArray", () => {
  it("แยกบรรทัด/คอมมา + ตัดว่าง", () => {
    expect(toArray("ขี้สงสัย, ใจดี\nตื่นเต้นง่าย\n\n")).toEqual([
      "ขี้สงสัย",
      "ใจดี",
      "ตื่นเต้นง่าย",
    ]);
  });
  it("ว่าง → []", () => expect(toArray("  ")).toEqual([]));
});
