import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { CreateAssetForm, type EpisodeOption } from "@/components/AssetForms";
import {
  ASSET_TYPES,
  ASSET_ROLES,
  TYPE_LABEL,
  ROLE_LABEL,
  isAssetType,
  isAssetRole,
  type AssetType,
  type AssetRole,
} from "@/lib/asset/validation";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 20;

type AssetRow = {
  id: string;
  title: string | null;
  type: AssetType;
  role: AssetRole | null;
  episode_id: string | null;
};

export default async function AssetsListPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ type?: string; role?: string; episode?: string; page?: string }>;
}) {
  const [{ id }, resolvedSearchParams] = await Promise.all([params, searchParams]);
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: ch } = await supabase
    .from("channels")
    .select("id, name, status")
    .eq("id", id)
    .maybeSingle();
  if (!ch) notFound();
  const channel = ch as { id: string; name: string; status: string };
  const approved = channel.status === "approved";

  const { data: epData } = await supabase
    .from("episodes")
    .select("id, title")
    .eq("channel_id", channel.id)
    .order("updated_at", { ascending: false });
  const episodes = (epData ?? []) as EpisodeOption[];
  const episodeTitle = new Map(episodes.map((e) => [e.id, e.title]));

  const typeFilter =
    resolvedSearchParams.type && isAssetType(resolvedSearchParams.type) ? resolvedSearchParams.type : null;
  const roleFilter =
    resolvedSearchParams.role && isAssetRole(resolvedSearchParams.role) ? resolvedSearchParams.role : null;
  const episodeFilter = resolvedSearchParams.episode?.trim() || null;
  const page = Math.max(1, Number(resolvedSearchParams.page ?? "1") || 1);
  const from = (page - 1) * PAGE_SIZE;

  let query = supabase
    .from("assets")
    .select("id, title, type, role, episode_id", { count: "exact" })
    .eq("channel_id", channel.id)
    .order("created_at", { ascending: false })
    .range(from, from + PAGE_SIZE - 1);
  if (typeFilter) query = query.eq("type", typeFilter);
  if (roleFilter) query = query.eq("role", roleFilter);
  if (episodeFilter === "none") query = query.is("episode_id", null);
  else if (episodeFilter) query = query.eq("episode_id", episodeFilter);

  const { data: aData, count } = await query;
  const assets = (aData ?? []) as AssetRow[];
  const total = count ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const pageHref = (p: number) => {
    const sp = new URLSearchParams();
    if (typeFilter) sp.set("type", typeFilter);
    if (roleFilter) sp.set("role", roleFilter);
    if (episodeFilter) sp.set("episode", episodeFilter);
    sp.set("page", String(p));
    return `?${sp.toString()}`;
  };

  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href={`/channels/${channel.id}`}>← กลับ {channel.name}</Link>
      </p>
      <h1>Asset & Rights</h1>
      <p style={{ color: "var(--muted)" }}>
        ช่อง {channel.name} · ทั้งหมด {total} asset
      </p>

      <form method="get" style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "end", margin: "16px 0" }}>
        <label className="auth-label" style={{ margin: 0 }}>
          ประเภท
          <select name="type" defaultValue={typeFilter ?? ""} className="auth-input">
            <option value="">ทั้งหมด</option>
            {ASSET_TYPES.map((t) => (
              <option key={t} value={t}>{TYPE_LABEL[t]}</option>
            ))}
          </select>
        </label>
        <label className="auth-label" style={{ margin: 0 }}>
          บทบาท
          <select name="role" defaultValue={roleFilter ?? ""} className="auth-input">
            <option value="">ทั้งหมด</option>
            {ASSET_ROLES.map((r) => (
              <option key={r} value={r}>{ROLE_LABEL[r]}</option>
            ))}
          </select>
        </label>
        <label className="auth-label" style={{ margin: 0 }}>
          ตอน
          <select name="episode" defaultValue={episodeFilter ?? ""} className="auth-input">
            <option value="">ทั้งหมด</option>
            <option value="none">ไม่ผูกตอน</option>
            {episodes.map((e) => (
              <option key={e.id} value={e.id}>{e.title}</option>
            ))}
          </select>
        </label>
        <button type="submit" className="auth-submit" style={{ width: "auto" }}>กรอง</button>
      </form>

      {assets.length === 0 ? (
        <p style={{ color: "var(--muted)" }}>ยังไม่มี asset ตามเงื่อนไข</p>
      ) : (
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ textAlign: "left", borderBottom: "1px solid var(--border)" }}>
              <th style={{ padding: "8px 4px" }}>ชื่อ</th>
              <th style={{ padding: "8px 4px" }}>ประเภท</th>
              <th style={{ padding: "8px 4px" }}>บทบาท</th>
              <th style={{ padding: "8px 4px" }}>ตอน</th>
            </tr>
          </thead>
          <tbody>
            {assets.map((a) => (
              <tr key={a.id} style={{ borderBottom: "1px solid var(--border)" }}>
                <td style={{ padding: "8px 4px" }}>
                  <Link href={`/assets/${a.id}`}>{a.title || "(ไม่มีชื่อ)"}</Link>
                </td>
                <td style={{ padding: "8px 4px" }}>{TYPE_LABEL[a.type]}</td>
                <td style={{ padding: "8px 4px", color: "var(--muted)" }}>
                  {a.role ? ROLE_LABEL[a.role] : "—"}
                </td>
                <td style={{ padding: "8px 4px", color: "var(--muted)" }}>
                  {a.episode_id ? episodeTitle.get(a.episode_id) ?? "—" : "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {totalPages > 1 && (
        <nav style={{ display: "flex", gap: 12, marginTop: 16, alignItems: "center" }}>
          {page > 1 && <Link href={pageHref(page - 1)}>← ก่อนหน้า</Link>}
          <span style={{ color: "var(--muted)" }}>หน้า {page} / {totalPages}</span>
          {page < totalPages && <Link href={pageHref(page + 1)}>ถัดไป →</Link>}
        </nav>
      )}

      <section style={{ marginTop: 32 }}>
        <h2>สร้าง asset ใหม่ (พร้อม rights)</h2>
        {approved ? (
          <CreateAssetForm channelId={channel.id} episodes={episodes} />
        ) : (
          <p style={{ color: "var(--warn)" }}>
            channel ยังเป็นร่าง — ต้องอนุมัติก่อนจึงจัดการ asset ได้
          </p>
        )}
      </section>
    </main>
  );
}
