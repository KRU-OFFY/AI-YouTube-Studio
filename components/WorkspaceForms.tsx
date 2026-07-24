"use client";

import { useFormState, useFormStatus } from "react-dom";
import {
  createWorkspace,
  renameWorkspace,
  type WorkspaceState,
} from "@/lib/workspace/actions";

const initialState: WorkspaceState = { error: null, message: null };

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="auth-submit" style={{ width: "auto" }}>
      {pending ? "กำลังบันทึก…" : label}
    </button>
  );
}

export function CreateWorkspaceForm() {
  const [state, formAction] = useFormState(createWorkspace, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 420 }}>
      <label className="auth-label">
        ชื่อ workspace
        <input name="name" required maxLength={80} className="auth-input" placeholder="เช่น Puifun Studio" />
      </label>
      <div style={{ display: "flex", gap: 12 }}>
        <label className="auth-label" style={{ flex: 1 }}>
          Timezone
          <input name="timezone" defaultValue="Asia/Bangkok" className="auth-input" />
        </label>
        <label className="auth-label" style={{ width: 120 }}>
          Currency
          <input name="currency" defaultValue="THB" className="auth-input" />
        </label>
      </div>
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      <SubmitButton label="สร้าง workspace" />
    </form>
  );
}

export function RenameWorkspaceForm({
  id,
  currentName,
}: {
  id: string;
  currentName: string;
}) {
  const [state, formAction] = useFormState(renameWorkspace, initialState);
  return (
    <form action={formAction} className="auth-form" style={{ maxWidth: 420 }}>
      <input type="hidden" name="id" value={id} />
      <label className="auth-label">
        ชื่อ workspace
        <input name="name" required maxLength={80} defaultValue={currentName} className="auth-input" />
      </label>
      {state.error && <p role="alert" className="auth-error">{state.error}</p>}
      {state.message && <p role="status" className="auth-ok">{state.message}</p>}
      <SubmitButton label="บันทึกชื่อ" />
    </form>
  );
}
