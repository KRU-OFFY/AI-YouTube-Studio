import { describe, it, expect } from "vitest";
import {
  isAssetType,
  isAssetRole,
  validateAssetTitle,
  validateStoragePath,
  validateRights,
  ASSET_TYPES,
  ASSET_ROLES,
} from "./validation";

describe("asset enum guards (mirror DB)", () => {
  it("type จริง → true, มั่ว → false", () => {
    expect(isAssetType("image")).toBe(true);
    expect(isAssetType("music")).toBe(false); // ไม่มีใน enum
    for (const t of ASSET_TYPES) expect(isAssetType(t)).toBe(true);
  });
  it("role จริง → true, มั่ว → false", () => {
    expect(isAssetRole("anchor")).toBe(true);
    expect(isAssetRole("boss")).toBe(false);
    for (const r of ASSET_ROLES) expect(isAssetRole(r)).toBe(true);
  });
});

describe("validateAssetTitle", () => {
  it("ว่างได้ (title optional) → null", () => {
    expect(validateAssetTitle("")).toBeNull();
  });
  it("ยาวเกิน → error", () => {
    expect(validateAssetTitle("x".repeat(161))).not.toBeNull();
  });
});

describe("validateStoragePath", () => {
  it("ว่าง → error (NOT NULL)", () => {
    expect(validateStoragePath("  ")).not.toBeNull();
  });
  it("มีค่า → null", () => {
    expect(validateStoragePath("https://ex/a.png")).toBeNull();
  });
});

describe("validateRights (rights ห้ามว่าง)", () => {
  it("tool_used ว่าง → error", () => {
    expect(validateRights({ toolUsed: "", exportedAt: "2026-08-04" })).not.toBeNull();
  });
  it("exported_at ว่าง → error", () => {
    expect(validateRights({ toolUsed: "firefly", exportedAt: "" })).not.toBeNull();
  });
  it("exported_at รูปแบบผิด → error", () => {
    expect(validateRights({ toolUsed: "firefly", exportedAt: "not-a-date" })).not.toBeNull();
  });
  it("ครบถูก → null", () => {
    expect(validateRights({ toolUsed: "firefly", exportedAt: "2026-08-04" })).toBeNull();
  });
});
