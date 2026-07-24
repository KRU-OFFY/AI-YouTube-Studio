"use client";

import { useFormState, useFormStatus } from "react-dom";
import Link from "next/link";
import type { AuthState } from "@/lib/auth/actions";

type AuthAction = (prev: AuthState, formData: FormData) => Promise<AuthState>;

const initialState: AuthState = { error: null, message: null };

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="auth-submit">
      {pending ? "กำลังดำเนินการ…" : label}
    </button>
  );
}

export function AuthForm({
  action,
  submitLabel,
  footer,
}: {
  action: AuthAction;
  submitLabel: string;
  footer: React.ReactNode;
}) {
  const [state, formAction] = useFormState(action, initialState);

  return (
    <form action={formAction} className="auth-form">
      <label className="auth-label">
        อีเมล
        <input
          type="email"
          name="email"
          autoComplete="email"
          required
          className="auth-input"
        />
      </label>

      <label className="auth-label">
        รหัสผ่าน
        <input
          type="password"
          name="password"
          autoComplete="current-password"
          required
          minLength={8}
          className="auth-input"
        />
      </label>

      {state.error && (
        <p role="alert" className="auth-error">
          {state.error}
        </p>
      )}
      {state.message && (
        <p role="status" className="auth-ok">
          {state.message}
        </p>
      )}

      <SubmitButton label={submitLabel} />

      <p className="auth-footer">{footer}</p>
    </form>
  );
}

export { Link };
