// Pure validation + state-machine helpers for episodes (unit-testable, no DB/network).
// ⚠️ ALLOWED_TRANSITIONS ต้องตรงกับ migration 0009 (public.episode_transition_allowed) เป๊ะ
// ฝั่ง DB คือ source of truth — ฝั่งนี้ใช้แค่ตัดสินใจว่าจะโชว์ปุ่มไหนบน UI

export const EPISODE_TITLE_MAX = 160;

export const EPISODE_STATUSES = [
  "draft",
  "scripted",
  "in_production",
  "qc",
  "ready",
  "published",
  "archived",
] as const;

export type EpisodeStatus = (typeof EPISODE_STATUSES)[number];

// ป้ายไทยสำหรับแสดงผล
export const STATUS_LABEL: Record<EpisodeStatus, string> = {
  draft: "ร่าง",
  scripted: "มีบทแล้ว",
  in_production: "กำลังผลิต",
  qc: "ตรวจคุณภาพ",
  ready: "พร้อมเผยแพร่",
  published: "เผยแพร่แล้ว",
  archived: "เก็บเข้ากรุ",
};

// allowed edge นอกเหนือจาก {any}→archived (ตรงกับ 0009)
const EXPLICIT_EDGES: ReadonlyArray<readonly [EpisodeStatus, EpisodeStatus]> = [
  ["draft", "scripted"],
  ["scripted", "in_production"],
  ["in_production", "qc"],
  ["in_production", "scripted"],
  ["qc", "ready"],
  ["qc", "in_production"],
  ["qc", "scripted"],
  ["ready", "published"],
  ["ready", "qc"],
];

export function isTransitionAllowed(
  from: EpisodeStatus,
  to: EpisodeStatus,
): boolean {
  // เก็บเข้ากรุได้จากทุกสถานะที่ยังไม่ archived
  if (to === "archived" && from !== "archived") return true;
  return EXPLICIT_EDGES.some(([f, t]) => f === from && t === to);
}

// รายการสถานะปลายทางที่ทำได้จาก from ปัจจุบัน (ไว้เรนเดอร์ปุ่ม)
export function allowedNextStatuses(from: EpisodeStatus): EpisodeStatus[] {
  return EPISODE_STATUSES.filter(
    (to) => to !== from && isTransitionAllowed(from, to),
  );
}

export function validateEpisodeTitle(title: string): string | null {
  const value = title.trim();
  if (!value) return "กรุณากรอกชื่อตอน";
  if (value.length > EPISODE_TITLE_MAX)
    return `ชื่อตอนต้องไม่เกิน ${EPISODE_TITLE_MAX} ตัวอักษร`;
  return null;
}

export function isEpisodeStatus(value: string): value is EpisodeStatus {
  return (EPISODE_STATUSES as readonly string[]).includes(value);
}
