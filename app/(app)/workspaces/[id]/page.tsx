import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { RenameWorkspaceForm } from "@/components/WorkspaceForms";
import { CreateChannelForm } from "@/components/ChannelForms";

export const dynamic = "force-dynamic";

type Workspace = {
  id: string;
  name: string;
  default_language: string;
  timezone: string;
  currency: string;
  created_at: string;
};

type Member = { user_id: string; role: string };

export default async function WorkspaceDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const supabase = createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // RLS: ถ้าไม่ใช่สมาชิก จะได้ null → 404
  const { data: ws } = await supabase
    .from("workspaces")
    .select("id, name, default_language, timezone, currency, created_at")
    .eq("id", params.id)
    .maybeSingle();

  if (!ws) notFound();
  const workspace = ws as Workspace;

  const { data: memberRows } = await supabase
    .from("workspace_members")
    .select("user_id, role")
    .eq("workspace_id", workspace.id);
  const members = (memberRows ?? []) as Member[];

  const myMembership = members.find((m) => m.user_id === user.id);
  const isOwner = myMembership?.role === "owner";

  const { data: channelRows } = await supabase
    .from("channels")
    .select("id, name, slug, status")
    .eq("workspace_id", workspace.id)
    .order("created_at", { ascending: true });
  const channels = (channelRows ?? []) as {
    id: string;
    name: string;
    slug: string;
    status: string;
  }[];

  const { data: auditRows } = await supabase
    .from("audit_logs")
    .select("id, action, result, actor_user_id, created_at")
    .eq("workspace_id", workspace.id)
    .order("created_at", { ascending: false })
    .limit(20);
  const auditLogs = (auditRows ?? []) as {
    id: string;
    action: string;
    result: string;
    actor_user_id: string | null;
    created_at: string;
  }[];

  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href="/workspaces">← Workspaces ทั้งหมด</Link>
      </p>
      <h1>{workspace.name}</h1>
      <p style={{ color: "var(--muted)" }}>
        {workspace.timezone} · {workspace.currency} · ภาษา {workspace.default_language}
        {" · "}สิทธิ์ของคุณ: <strong>{myMembership?.role ?? "-"}</strong>
      </p>

      <section style={{ marginTop: 32 }}>
        <h2 style={{ marginBottom: 8 }}>สมาชิก ({members.length})</h2>
        <ul style={{ paddingLeft: 18 }}>
          {members.map((m) => (
            <li key={m.user_id} style={{ marginBottom: 4 }}>
              <code style={{ fontSize: 13 }}>{m.user_id}</code>
              {" — "}
              {m.role}
              {m.user_id === user.id && " (คุณ)"}
            </li>
          ))}
        </ul>
      </section>

      <section style={{ marginTop: 32 }}>
        <h2 style={{ marginBottom: 8 }}>Channels ({channels.length})</h2>
        {channels.length === 0 && (
          <p style={{ color: "var(--muted)" }}>ยังไม่มี channel</p>
        )}
        <ul style={{ paddingLeft: 18 }}>
          {channels.map((c) => (
            <li key={c.id} style={{ marginBottom: 6 }}>
              <Link href={`/channels/${c.id}`}>{c.name}</Link>{" "}
              <span style={{ color: "var(--muted)", fontSize: 13 }}>
                · /{c.slug} ·{" "}
                <span style={{ color: c.status === "approved" ? "var(--ok)" : "var(--warn)" }}>
                  {c.status === "approved" ? "อนุมัติแล้ว" : "ร่าง (draft)"}
                </span>
              </span>
            </li>
          ))}
        </ul>
        {isOwner ? (
          <div style={{ marginTop: 16 }}>
            <h3 style={{ marginBottom: 8, fontSize: 15 }}>สร้าง channel ใหม่</h3>
            <CreateChannelForm workspaceId={workspace.id} />
          </div>
        ) : (
          <p style={{ color: "var(--muted)" }}>เฉพาะ owner สร้าง channel ได้</p>
        )}
      </section>

      <section style={{ marginTop: 32 }}>
        <h2 style={{ marginBottom: 12 }}>แก้ชื่อ workspace</h2>
        {isOwner ? (
          <RenameWorkspaceForm id={workspace.id} currentName={workspace.name} />
        ) : (
          <p style={{ color: "var(--muted)" }}>
            เฉพาะ owner แก้ชื่อได้ (สิทธิ์ของคุณคือ {myMembership?.role ?? "-"})
          </p>
        )}
      </section>

      <section style={{ marginTop: 32 }}>
        <h2 style={{ marginBottom: 8 }}>Audit log ล่าสุด ({auditLogs.length})</h2>
        {auditLogs.length === 0 ? (
          <p style={{ color: "var(--muted)" }}>ยังไม่มีบันทึก</p>
        ) : (
          <ul style={{ paddingLeft: 18, fontSize: 14 }}>
            {auditLogs.map((a) => (
              <li key={a.id} style={{ marginBottom: 4 }}>
                <code>{a.action}</code>{" "}
                <span style={{ color: a.result === "success" ? "var(--ok)" : "var(--err)" }}>
                  {a.result}
                </span>
                <span style={{ color: "var(--muted)" }}>
                  {" · "}
                  {new Date(a.created_at).toLocaleString("th-TH", {
                    timeZone: "Asia/Bangkok",
                  })}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
