"use client";

import { useFormState, useFormStatus } from "react-dom";
import {
  linkCharacter,
  unlinkCharacter,
  type EpisodeState,
} from "@/lib/episode/actions";

const initialState: EpisodeState = { error: null, message: null };

export type CharacterOption = { id: string; name: string };

function AddButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="auth-submit" style={{ width: "auto" }}>
      {pending ? "กำลังผูก…" : "ผูกตัวละคร"}
    </button>
  );
}

export function EpisodeCharacters({
  episodeId,
  linked,
  available,
}: {
  episodeId: string;
  linked: CharacterOption[];
  available: CharacterOption[]; // characters ของ channel เดียวกันที่ยังไม่ผูก
}) {
  const [state, formAction] = useFormState(linkCharacter, initialState);

  return (
    <div>
      {linked.length === 0 ? (
        <p style={{ color: "var(--muted)" }}>ยังไม่มีตัวละครผูกกับตอนนี้</p>
      ) : (
        <ul style={{ paddingLeft: 18 }}>
          {linked.map((c) => (
            <li key={c.id} style={{ marginBottom: 6 }}>
              {c.name}{" "}
              <form action={unlinkCharacter} style={{ display: "inline" }}>
                <input type="hidden" name="episode_id" value={episodeId} />
                <input type="hidden" name="character_id" value={c.id} />
                <button
                  type="submit"
                  style={{ marginLeft: 8, color: "var(--warn)", background: "none", border: "none", cursor: "pointer" }}
                >
                  ถอด
                </button>
              </form>
            </li>
          ))}
        </ul>
      )}

      {available.length > 0 ? (
        <form action={formAction} style={{ display: "flex", gap: 8, alignItems: "center", marginTop: 12 }}>
          <input type="hidden" name="episode_id" value={episodeId} />
          <select name="character_id" required className="auth-input" style={{ maxWidth: 280 }}>
            <option value="">— เลือกตัวละคร —</option>
            {available.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
          <AddButton />
        </form>
      ) : (
        <p style={{ color: "var(--muted)", marginTop: 12 }}>ผูกตัวละครทั้งหมดของช่องนี้แล้ว</p>
      )}
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
    </div>
  );
}
