"use client";

import { useFormState, useFormStatus } from "react-dom";
import {
  createAssetWithRights,
  updateAssetWithRights,
  type AssetState,
} from "@/lib/asset/actions";
import {
  ASSET_TYPES,
  ASSET_ROLES,
  TYPE_LABEL,
  ROLE_LABEL,
} from "@/lib/asset/validation";

const initialState: AssetState = { error: null, message: null };

export type EpisodeOption = { id: string; title: string };

export type AssetDefaults = {
  type: string;
  role: string | null;
  title: string | null;
  episode_id: string | null;
  storage_path: string;
  source_tool: string | null;
  tool_used: string;
  plan: string | null;
  model: string | null;
  prompt_used: string | null;
  source_url: string | null;
  license_note: string | null;
  exported_at: string; // yyyy-mm-dd
};

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="auth-submit" style={{ width: "auto" }}>
      {pending ? "กำลังบันทึก…" : label}
    </button>
  );
}

function AssetFields({
  episodes,
  d,
  showEpisode,
}: {
  episodes: EpisodeOption[];
  d?: Partial<AssetDefaults>;
  showEpisode: boolean;
}) {
  return (
    <>
      <label className="auth-label">
        ประเภท
        <select name="type" defaultValue={d?.type ?? "image"} className="auth-input" required>
          {ASSET_TYPES.map((t) => (
            <option key={t} value={t}>{TYPE_LABEL[t]}</option>
          ))}
        </select>
      </label>
      <label className="auth-label">
        บทบาท (role)
        <select name="role" defaultValue={d?.role ?? ""} className="auth-input">
          <option value="">— ไม่ระบุ —</option>
          {ASSET_ROLES.map((r) => (
            <option key={r} value={r}>{ROLE_LABEL[r]}</option>
          ))}
        </select>
      </label>
      <label className="auth-label">
        ชื่อ asset
        <input name="title" maxLength={160} defaultValue={d?.title ?? ""} className="auth-input" />
      </label>
      {showEpisode && (
        <label className="auth-label">
          ผูกตอน (optional)
          <select name="episode_id" defaultValue={d?.episode_id ?? ""} className="auth-input">
            <option value="">— ไม่ผูกตอน —</option>
            {episodes.map((e) => (
              <option key={e.id} value={e.id}>{e.title}</option>
            ))}
          </select>
        </label>
      )}
      <label className="auth-label">
        ที่อยู่ไฟล์ (path หรือ URL)
        <input name="storage_path" required defaultValue={d?.storage_path ?? ""} className="auth-input" placeholder="assets/... หรือ https://..." />
      </label>
      <label className="auth-label">
        เครื่องมือที่สร้างไฟล์ (source_tool)
        <input name="source_tool" defaultValue={d?.source_tool ?? ""} className="auth-input" />
      </label>

      <fieldset style={{ border: "1px solid var(--border)", borderRadius: 8, padding: 12, marginTop: 8 }}>
        <legend>สิทธิ์/ที่มา (rights — ห้ามว่าง)</legend>
        <label className="auth-label">
          เครื่องมือที่ใช้ (tool_used) *
          <input name="tool_used" required defaultValue={d?.tool_used ?? ""} className="auth-input" placeholder="เช่น Adobe Firefly" />
        </label>
        <label className="auth-label">
          วันที่ส่งออก (exported_at) *
          <input type="date" name="exported_at" required defaultValue={d?.exported_at ?? ""} className="auth-input" />
        </label>
        <label className="auth-label">
          แพ็กเกจ/สิทธิ์ (plan)
          <input name="plan" defaultValue={d?.plan ?? ""} className="auth-input" placeholder="paid / free / enterprise" />
        </label>
        <label className="auth-label">
          โมเดล (model)
          <input name="model" defaultValue={d?.model ?? ""} className="auth-input" />
        </label>
        <label className="auth-label">
          prompt ที่ใช้
          <textarea name="prompt_used" rows={3} defaultValue={d?.prompt_used ?? ""} className="auth-input" />
        </label>
        <label className="auth-label">
          แหล่งอ้างอิง (source_url)
          <input name="source_url" defaultValue={d?.source_url ?? ""} className="auth-input" />
        </label>
        <label className="auth-label">
          หมายเหตุสิทธิ์ (license_note)
          <input name="license_note" defaultValue={d?.license_note ?? ""} className="auth-input" />
        </label>
      </fieldset>
    </>
  );
}

export function CreateAssetForm({
  channelId,
  episodes,
}: {
  channelId: string;
  episodes: EpisodeOption[];
}) {
  const [state, formAction] = useFormState(createAssetWithRights, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 560 }}>
      <input type="hidden" name="channel_id" value={channelId} />
      <AssetFields episodes={episodes} showEpisode />
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      <SubmitButton label="สร้าง asset + rights" />
    </form>
  );
}

export function EditAssetForm({
  assetId,
  defaults,
  episodes,
}: {
  assetId: string;
  defaults: AssetDefaults;
  episodes: EpisodeOption[];
}) {
  const [state, formAction] = useFormState(updateAssetWithRights, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 560 }}>
      <input type="hidden" name="asset_id" value={assetId} />
      <AssetFields episodes={episodes} d={defaults} showEpisode={false} />
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      {state.message && <p style={{ color: "var(--ok)" }}>{state.message}</p>}
      <SubmitButton label="บันทึกการแก้ไข" />
    </form>
  );
}
