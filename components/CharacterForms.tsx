"use client";

import { useFormState, useFormStatus } from "react-dom";
import {
  createCharacter,
  updateCharacter,
  type CharacterState,
} from "@/lib/character/actions";
import {
  CHARACTER_TYPES,
  TYPE_LABEL,
  PILLAR_CODES,
} from "@/lib/character/validation";

const initialState: CharacterState = { error: null, message: null };

export type CharacterDefaults = {
  name: string;
  slug: string;
  type: string;
  role: string | null;
  species: string | null;
  description: string | null;
  image_prompt: string | null;
  anchor_image_url: string | null;
  appearance: unknown;
  voice: unknown;
  personality: string[];
  forbidden: string[];
  appears_in: string[];
};

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="auth-submit" style={{ width: "auto" }}>
      {pending ? "กำลังบันทึก…" : label}
    </button>
  );
}

function jsonText(v: unknown): string {
  if (v == null) return "";
  if (typeof v === "object" && Object.keys(v as object).length === 0) return "";
  return JSON.stringify(v, null, 2);
}

function Fields({ d }: { d?: Partial<CharacterDefaults> }) {
  const appearsIn = d?.appears_in ?? [];
  return (
    <>
      <label className="auth-label">
        ชื่อ
        <input name="name" required maxLength={80} defaultValue={d?.name ?? ""} className="auth-input" />
      </label>
      <label className="auth-label">
        slug (a-z, 0-9, -)
        <input name="slug" required defaultValue={d?.slug ?? ""} className="auth-input" placeholder="nong-pui" />
      </label>
      <label className="auth-label">
        ประเภท
        <select name="type" defaultValue={d?.type ?? "character"} className="auth-input" required>
          {CHARACTER_TYPES.map((t) => (
            <option key={t} value={t}>{TYPE_LABEL[t]}</option>
          ))}
        </select>
      </label>
      <label className="auth-label">
        บทบาท (role)
        <input name="role" defaultValue={d?.role ?? ""} className="auth-input" />
      </label>
      <label className="auth-label">
        สปีชีส์ (species)
        <input name="species" defaultValue={d?.species ?? ""} className="auth-input" />
      </label>
      <label className="auth-label">
        คำอธิบายสั้น
        <input name="description" defaultValue={d?.description ?? ""} className="auth-input" />
      </label>

      <fieldset style={{ border: "1px solid var(--border)", borderRadius: 8, padding: 12, marginTop: 8 }}>
        <legend>ปรากฏใน pillar (appears_in — กฎแนะนำ)</legend>
        <div style={{ display: "flex", gap: 16 }}>
          {PILLAR_CODES.map((c) => (
            <label key={c} style={{ display: "flex", gap: 4, alignItems: "center" }}>
              <input type="checkbox" name={`appears_${c}`} defaultChecked={appearsIn.includes(c)} />
              {c}
            </label>
          ))}
        </div>
      </fieldset>

      <label className="auth-label">
        บุคลิก (personality — คั่นด้วยคอมมา/บรรทัด)
        <textarea name="personality" rows={2} defaultValue={(d?.personality ?? []).join(", ")} className="auth-input" />
      </label>
      <label className="auth-label">
        ข้อห้าม (forbidden — คั่นด้วยคอมมา/บรรทัด)
        <textarea name="forbidden" rows={2} defaultValue={(d?.forbidden ?? []).join(", ")} className="auth-input" />
      </label>
      <label className="auth-label">
        canonical prompt (image_prompt)
        <textarea name="image_prompt" rows={3} defaultValue={d?.image_prompt ?? ""} className="auth-input" />
      </label>
      <label className="auth-label">
        anchor image URL (optional)
        <input name="anchor_image_url" defaultValue={d?.anchor_image_url ?? ""} className="auth-input" />
      </label>
      <label className="auth-label">
        appearance (JSON · ว่างได้)
        <textarea name="appearance" rows={3} defaultValue={jsonText(d?.appearance)} className="auth-input" />
      </label>
      <label className="auth-label">
        voice (JSON · ว่างได้)
        <textarea name="voice" rows={3} defaultValue={jsonText(d?.voice)} className="auth-input" />
      </label>
    </>
  );
}

export function CreateCharacterForm({ channelId }: { channelId: string }) {
  const [state, formAction] = useFormState(createCharacter, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 560 }}>
      <input type="hidden" name="channel_id" value={channelId} />
      <Fields />
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      <SubmitButton label="สร้างตัวละคร" />
    </form>
  );
}

export function EditCharacterForm({
  characterId,
  defaults,
}: {
  characterId: string;
  defaults: CharacterDefaults;
}) {
  const [state, formAction] = useFormState(updateCharacter, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 560 }}>
      <input type="hidden" name="id" value={characterId} />
      <Fields d={defaults} />
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      {state.message && <p style={{ color: "var(--ok)" }}>{state.message}</p>}
      <SubmitButton label="บันทึกการแก้ไข" />
    </form>
  );
}
