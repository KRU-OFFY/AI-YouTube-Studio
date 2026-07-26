import type { SupabaseClient } from "@supabase/supabase-js";
import { sanitizeMetadata } from "@/lib/audit/sanitize";

export type AuditResult = "success" | "failure";

export type AuditInput = {
  action: string;
  entityType?: string | null;
  entityId?: string | null;
  workspaceId?: string | null;
  result?: AuditResult;
  metadata?: Record<string, unknown>;
};

// helper กลาง (reusable) — best-effort: ไม่ทำให้ action หลักพัง
// แต่ถ้า log ล้ม ต้องยิง error เข้า monitoring (ห้ามเงียบสนิท)
export async function logAudit(
  supabase: SupabaseClient,
  input: AuditInput,
): Promise<void> {
  try {
    const { error } = await supabase.rpc("log_audit", {
      p_action: input.action,
      p_entity_type: input.entityType ?? null,
      p_entity_id: input.entityId ?? null,
      p_workspace_id: input.workspaceId ?? null,
      p_result: input.result ?? "success",
      p_metadata: sanitizeMetadata(input.metadata ?? {}),
    });
    if (error) {
      console.error("[audit] log_audit failed:", input.action, error.message);
    }
  } catch (err) {
    console.error("[audit] log_audit threw:", input.action, err);
  }
}
