import { describe, it, expect } from "vitest";
import {
  isTransitionAllowed,
  allowedNextStatuses,
  validateEpisodeTitle,
  isEpisodeStatus,
  EPISODE_STATUSES,
} from "./validation";

describe("episode transition map (mirror ของ migration 0009)", () => {
  it("อนุญาต edge ที่ถูกต้อง", () => {
    expect(isTransitionAllowed("draft", "scripted")).toBe(true);
    expect(isTransitionAllowed("scripted", "in_production")).toBe(true);
    expect(isTransitionAllowed("in_production", "qc")).toBe(true);
    expect(isTransitionAllowed("in_production", "scripted")).toBe(true);
    expect(isTransitionAllowed("qc", "ready")).toBe(true);
    expect(isTransitionAllowed("qc", "in_production")).toBe(true);
    expect(isTransitionAllowed("qc", "scripted")).toBe(true);
    expect(isTransitionAllowed("ready", "published")).toBe(true);
    expect(isTransitionAllowed("ready", "qc")).toBe(true);
  });

  it("ปฏิเสธ edge ที่ข้ามขั้น / ย้อนผิด", () => {
    expect(isTransitionAllowed("draft", "published")).toBe(false);
    expect(isTransitionAllowed("draft", "qc")).toBe(false);
    expect(isTransitionAllowed("in_production", "published")).toBe(false);
    expect(isTransitionAllowed("scripted", "draft")).toBe(false); // ไม่มีใน handoff graph
    expect(isTransitionAllowed("published", "ready")).toBe(false);
  });

  it("{any}→archived ได้จากทุกสถานะที่ยังไม่ archived", () => {
    for (const s of EPISODE_STATUSES) {
      expect(isTransitionAllowed(s, "archived")).toBe(s !== "archived");
    }
  });

  it("archived เป็น terminal (ออกไปไหนไม่ได้)", () => {
    expect(allowedNextStatuses("archived")).toEqual([]);
  });

  it("allowedNextStatuses คืนรายการถูก", () => {
    expect(allowedNextStatuses("draft").sort()).toEqual(["archived", "scripted"]);
    expect(allowedNextStatuses("ready").sort()).toEqual(
      ["archived", "published", "qc"].sort(),
    );
  });
});

describe("validateEpisodeTitle", () => {
  it("ว่าง → error", () => {
    expect(validateEpisodeTitle("   ")).not.toBeNull();
  });
  it("ยาวเกิน → error", () => {
    expect(validateEpisodeTitle("x".repeat(161))).not.toBeNull();
  });
  it("ปกติ → null", () => {
    expect(validateEpisodeTitle("ตอนแรก")).toBeNull();
  });
});

describe("isEpisodeStatus", () => {
  it("ค่า enum จริง → true", () => {
    expect(isEpisodeStatus("qc")).toBe(true);
  });
  it("ค่ามั่ว → false", () => {
    expect(isEpisodeStatus("banana")).toBe(false);
  });
});
