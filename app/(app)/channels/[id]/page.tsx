import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { approveChannel } from "@/lib/channel/actions";

export const dynamic = "force-dynamic";

type Channel = {
  id: string;
  workspace_id: string;
  name: string;
  slug: string;
  handle: string | null;
  made_for_kids_default: boolean;
  status: string;
};

export default async function ChannelDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const supabase = createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // RLS: ไม่ใช่สมาชิก → null → 404
  const { data: ch } = await supabase
    .from("channels")
    .select("id, workspace_id, name, slug, handle, made_for_kids_default, status")
    .eq("id", params.id)
    .maybeSingle();
  if (!ch) notFound();
  const channel = ch as Channel;

  // ตรวจสิทธิ์ owner ของ workspace (สำหรับปุ่มอนุมัติ)
  const { data: membership } = await supabase
    .from("workspace_members")
    .select("role")
    .eq("workspace_id", channel.workspace_id)
    .eq("user_id", user.id)
    .maybeSingle();
  const isOwner = (membership as { role?: string } | null)?.role === "owner";

  const [{ count: pillars }, { count: characters }, { count: episodes }, { count: fwords }] =
    await Promise.all([
      supabase.from("pillars").select("id", { count: "exact", head: true }).eq("channel_id", channel.id),
      supabase.from("characters").select("id", { count: "exact", head: true }).eq("channel_id", channel.id),
      supabase.from("episodes").select("id", { count: "exact", head: true }).eq("channel_id", channel.id),
      supabase.from("forbidden_words").select("id", { count: "exact", head: true }).eq("channel_id", channel.id),
    ]);

  const approved = channel.status === "approved";

  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href={`/workspaces/${channel.workspace_id}`}>← กลับ workspace</Link>
      </p>
      <h1>{channel.name}</h1>
      <p style={{ color: "var(--muted)" }}>
        /{channel.slug}
        {channel.handle ? ` · ${channel.handle}` : ""} · Made for Kids:{" "}
        {channel.made_for_kids_default ? "ใช่" : "ไม่"} · สถานะ:{" "}
        <strong style={{ color: approved ? "var(--ok)" : "var(--warn)" }}>
          {approved ? "อนุมัติแล้ว" : "ร่าง (draft)"}
        </strong>
      </p>

      <section style={{ marginTop: 24 }}>
        {!approved && (
          <div
            style={{
              padding: 16,
              border: "1px solid var(--warn)",
              borderRadius: 8,
              marginBottom: 16,
            }}
          >
            <p style={{ marginTop: 0 }}>
              <strong>Gate 0:</strong> channel ยังเป็นร่าง — ยังสร้าง episode
              (คอนเทนต์) ไม่ได้จนกว่าจะอนุมัติ (บังคับที่ระดับฐานข้อมูล)
            </p>
            {isOwner ? (
              <form action={approveChannel}>
                <input type="hidden" name="id" value={channel.id} />
                <button type="submit" className="auth-submit" style={{ width: "auto" }}>
                  อนุมัติ channel นี้
                </button>
              </form>
            ) : (
              <p style={{ color: "var(--muted)", marginBottom: 0 }}>
                เฉพาะ owner อนุมัติได้
              </p>
            )}
          </div>
        )}

        <h2 style={{ marginBottom: 8 }}>ข้อมูลในช่อง</h2>
        <ul style={{ paddingLeft: 18 }}>
          <li>Content pillars: {pillars ?? 0}</li>
          <li>Characters: {characters ?? 0}</li>
          <li>
            Episodes: {episodes ?? 0} ·{" "}
            <Link href={`/channels/${channel.id}/episodes`}>จัดการตอน →</Link>
          </li>
          <li>Forbidden words: {fwords ?? 0}</li>
        </ul>
      </section>
    </main>
  );
}
