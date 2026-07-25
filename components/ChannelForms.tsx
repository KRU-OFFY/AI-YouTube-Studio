"use client";

import { useFormState, useFormStatus } from "react-dom";
import { createChannel, type ChannelState } from "@/lib/channel/actions";

const initialState: ChannelState = { error: null, message: null };

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="auth-submit" style={{ width: "auto" }}>
      {pending ? "กำลังบันทึก…" : label}
    </button>
  );
}

export function CreateChannelForm({ workspaceId }: { workspaceId: string }) {
  const [state, formAction] = useFormState(createChannel, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 420 }}>
      <input type="hidden" name="workspace_id" value={workspaceId} />
      <label className="auth-label">
        ชื่อ channel
        <input name="name" required maxLength={80} className="auth-input" placeholder="เช่น ปุยฝัน" />
      </label>
      <label className="auth-label">
        slug (a-z, 0-9, -)
        <input name="slug" required className="auth-input" placeholder="puifun" />
      </label>
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      <SubmitButton label="สร้าง channel" />
    </form>
  );
}
