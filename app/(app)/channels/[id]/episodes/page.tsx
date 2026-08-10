import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { CreateEpisodeForm, type PillarOption } from "@/components/EpisodeForms";
import {
  EPISODE_STATUSES,
  STATUS_LABEL,
  isEpisodeStatus,
  type EpisodeStatus,
} from "@/lib/episode/validation";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 20;

type EpisodeRow = {
  id: string;
  title: string;
  status: EpisodeStatus;
  pillar_id: string | null;
  updated_at: string;
};

export default async function EpisodesListPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ status?: string; pillar?: string; page?: string }>;
}) {
  const [{ id }, resolvedSearchParams] = await Promise.all([params, searchParams]);
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: ch } = await supabase
    .from("channels")
    .select("id, workspace_id, name, slug, status")
    .eq("id", id)
    .maybeSingle();
  if (!ch) notFound();
  const channel = ch as {
    id: string;
    workspace_id: string;
    name: string;
    slug: string;
    status: string;
  };
  const approved = channel.status === "approved";

  const { data: pillarsData } = await supabase
    .from("pillars")
    .select("id, name")
    .eq("channel_id", channel.id)
    .order("name");
  const pillars = (pillarsData ?? []) as PillarOption[];
  const pillarName = new Map(pillars.map((p) => [p.id, p.name]));

  // ── filters + pagination ──
  const statusFilter =
    resolvedSearchParams.status && isEpisodeStatus(resolvedSearchParams.status)
      ? resolvedSearchParams.status
      : null;
  const pillarFilter = resolvedSearchParams.pillar?.trim() || null;
  const page = Math.max(1, Number(resolvedSearchParams.page ?? "1") || 1);
  const from = (page - 1) * PAGE_SIZE;

  // NFR-010: ไม่ดึง script / seed_data (binary/หนัก) ในหน้า list
  let query = supabase
    .from("episodes")
    .select("id, title, status, pillar_id, updated_at", { count: "exact" })
    .eq("channel_id", channel.id)
    .order("updated_at", { ascending: false })
    .range(from, from + PAGE_SIZE - 1);
  if (statusFilter) query = query.eq("status", statusFilter);
  if (pillarFilter) query = query.eq("pillar_id", pillarFilter);

  const { data: epData, count } = await query;
  const episodes = (epData ?? []) as EpisodeRow[];
  const total = count ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const pageHref = (p: number) => {
    const sp = new URLSearchParams();
    if (statusFilter) sp.set("status", statusFilter);
    if (pillarFilter) sp.set("pillar", pillarFilter);
    sp.set("page", String(p));
    return `?${sp.toString()}`;
  };

  return (
    <main style={{ maxWidth: 820, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href={`/channels/${channel.id}`}>← กลับ {channel.name}</Link>
      </p>
      <h1>ตอน (episodes)</h1>
      <p style={{ color: "var(--muted)" }}>
        ช่อง {channel.name} · ทั้งหมด {total} ตอน
      </p>

      {/* filter (GET form) */}
      <form method="get" style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "end", margin: "16px 0" }}>
        <label className="auth-label" style={{ margin: 0 }}>
          สถานะ
          <select name="status" defaultValue={statusFilter ?? ""} className="auth-input">
            <option value="">ทั้งหมด</option>
            {EPISODE_STATUSES.map((s) => (
              <option key={s} value={s}>
                {STATUS_LABEL[s]}
              </option>
            ))}
          </select>
        </label>
        <label className="auth-label" style={{ margin: 0 }}>
          เสาเนื้อหา
          <select name="pillar" defaultValue={pillarFilter ?? ""} className="auth-input">
            <option value="">ทั้งหมด</option>
            {pillars.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </label>
        <button type="submit" className="auth-submit" style={{ width: "auto" }}>
          กรอง
        </button>
      </form>

      {/* list */}
      {episodes.length === 0 ? (
        <p style={{ color: "var(--muted)" }}>ยังไม่มีตอนตามเงื่อนไข</p>
      ) : (
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ textAlign: "left", borderBottom: "1px solid var(--border)" }}>
              <th style={{ padding: "8px 4px" }}>ชื่อตอน</th>
              <th style={{ padding: "8px 4px" }}>สถานะ</th>
              <th style={{ padding: "8px 4px" }}>เสาเนื้อหา</th>
            </tr>
          </thead>
          <tbody>
            {episodes.map((ep) => (
              <tr key={ep.id} style={{ borderBottom: "1px solid var(--border)" }}>
                <td style={{ padding: "8px 4px" }}>
                  <Link href={`/episodes/${ep.id}`}>{ep.title}</Link>
                </td>
                <td style={{ padding: "8px 4px" }}>{STATUS_LABEL[ep.status]}</td>
                <td style={{ padding: "8px 4px", color: "var(--muted)" }}>
                  {ep.pillar_id ? pillarName.get(ep.pillar_id) ?? "—" : "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {/* pagination */}
      {totalPages > 1 && (
        <nav style={{ display: "flex", gap: 12, marginTop: 16, alignItems: "center" }}>
          {page > 1 && <Link href={pageHref(page - 1)}>← ก่อนหน้า</Link>}
          <span style={{ color: "var(--muted)" }}>
            หน้า {page} / {totalPages}
          </span>
          {page < totalPages && <Link href={pageHref(page + 1)}>ถัดไป →</Link>}
        </nav>
      )}

      {/* create */}
      <section style={{ marginTop: 32 }}>
        <h2>สร้างตอนใหม่</h2>
        {approved ? (
          <CreateEpisodeForm channelId={channel.id} pillars={pillars} />
        ) : (
          <p style={{ color: "var(--warn)" }}>
            channel ยังเป็นร่าง — ต้องอนุมัติก่อนจึงสร้างตอนได้ (Gate 0)
          </p>
        )}
      </section>
    </main>
  );
}
