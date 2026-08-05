"use client";

import { useFormState, useFormStatus } from "react-dom";
import {
  createEpisode,
  updateEpisode,
  transitionEpisode,
  type EpisodeState,
} from "@/lib/episode/actions";
import {
  allowedNextStatuses,
  STATUS_LABEL,
  type EpisodeStatus,
} from "@/lib/episode/validation";

const initialState: EpisodeState = { error: null, message: null };

export type PillarOption = { id: string; name: string };

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="auth-submit" style={{ width: "auto" }}>
      {pending ? "กำลังบันทึก…" : label}
    </button>
  );
}

function PillarSelect({
  pillars,
  defaultValue,
}: {
  pillars: PillarOption[];
  defaultValue?: string | null;
}) {
  return (
    <label className="auth-label">
      เสาเนื้อหา (pillar)
      <select name="pillar_id" defaultValue={defaultValue ?? ""} className="auth-input">
        <option value="">— ไม่ระบุ —</option>
        {pillars.map((p) => (
          <option key={p.id} value={p.id}>
            {p.name}
          </option>
        ))}
      </select>
    </label>
  );
}

export function CreateEpisodeForm({
  channelId,
  pillars,
}: {
  channelId: string;
  pillars: PillarOption[];
}) {
  const [state, formAction] = useFormState(createEpisode, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 480 }}>
      <input type="hidden" name="channel_id" value={channelId} />
      <label className="auth-label">
        ชื่อตอน
        <input name="title" required maxLength={160} className="auth-input" placeholder="เช่น นิทานคืนที่ดาวหล่น" />
      </label>
      <PillarSelect pillars={pillars} />
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      <SubmitButton label="สร้างตอน" />
    </form>
  );
}

export function EditEpisodeForm({
  episode,
  pillars,
}: {
  episode: { id: string; title: string; script: string | null; pillar_id: string | null };
  pillars: PillarOption[];
}) {
  const [state, formAction] = useFormState(updateEpisode, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 640 }}>
      <input type="hidden" name="id" value={episode.id} />
      <label className="auth-label">
        ชื่อตอน
        <input name="title" required maxLength={160} defaultValue={episode.title} className="auth-input" />
      </label>
      <PillarSelect pillars={pillars} defaultValue={episode.pillar_id} />
      <label className="auth-label">
        บท (script)
        <textarea name="script" rows={10} defaultValue={episode.script ?? ""} className="auth-input" />
      </label>
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      {state.message && <p style={{ color: "var(--ok)" }}>{state.message}</p>}
      <SubmitButton label="บันทึกการแก้ไข" />
    </form>
  );
}

export function TransitionControls({
  episodeId,
  status,
}: {
  episodeId: string;
  status: EpisodeStatus;
}) {
  const [state, formAction] = useFormState(transitionEpisode, initialState);
  const nexts = allowedNextStatuses(status);

  if (nexts.length === 0) {
    return <p style={{ color: "var(--muted)" }}>สถานะปัจจุบันเป็นขั้นสุดท้าย — เปลี่ยนต่อไม่ได้</p>;
  }

  return (
    <div>
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        {nexts.map((to) => (
          <form key={to} action={formAction}>
            <input type="hidden" name="id" value={episodeId} />
            <input type="hidden" name="to" value={to} />
            <button type="submit" className="auth-submit" style={{ width: "auto" }}>
              → {STATUS_LABEL[to]}
            </button>
          </form>
        ))}
      </div>
      {state.error && <p role="alert" className="auth-error" style={{ marginTop: 8 }}>{state.error}</p>}
    </div>
  );
}
