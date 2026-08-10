import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { CreateCharacterForm } from "@/components/CharacterForms";
import {
  CHARACTER_TYPES,
  TYPE_LABEL,
  isCharacterType,
  type CharacterType,
} from "@/lib/character/validation";

export const dynamic = "force-dynamic";

type CharacterRow = {
  id: string;
  name: string;
  slug: string;
  type: CharacterType;
  role: string | null;
  appears_in: string[];
};

export default async function CharactersListPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams: { type?: string };
}) {
  const supabase = createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: ch } = await supabase
    .from("channels")
    .select("id, name")
    .eq("id", params.id)
    .maybeSingle();
  if (!ch) notFound();
  const channel = ch as { id: string; name: string };

  const typeFilter =
    searchParams.type && isCharacterType(searchParams.type) ? searchParams.type : null;

  let query = supabase
    .from("characters")
    .select("id, name, slug, type, role, appears_in")
    .eq("channel_id", channel.id)
    .order("name");
  if (typeFilter) query = query.eq("type", typeFilter);

  const { data: rows } = await query;
  const characters = (rows ?? []) as CharacterRow[];

  return (
    <main style={{ maxWidth: 820, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href={`/channels/${channel.id}`}>← กลับ {channel.name}</Link>
      </p>
      <h1>ตัวละคร (Character Bible)</h1>
      <p style={{ color: "var(--muted)" }}>ช่อง {channel.name} · ทั้งหมด {characters.length}</p>

      <form method="get" style={{ display: "flex", gap: 12, alignItems: "end", margin: "16px 0" }}>
        <label className="auth-label" style={{ margin: 0 }}>
          ประเภท
          <select name="type" defaultValue={typeFilter ?? ""} className="auth-input">
            <option value="">ทั้งหมด</option>
            {CHARACTER_TYPES.map((t) => (
              <option key={t} value={t}>{TYPE_LABEL[t]}</option>
            ))}
          </select>
        </label>
        <button type="submit" className="auth-submit" style={{ width: "auto" }}>กรอง</button>
      </form>

      {characters.length === 0 ? (
        <p style={{ color: "var(--muted)" }}>ยังไม่มีตัวละครตามเงื่อนไข</p>
      ) : (
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ textAlign: "left", borderBottom: "1px solid var(--border)" }}>
              <th style={{ padding: "8px 4px" }}>ชื่อ</th>
              <th style={{ padding: "8px 4px" }}>ประเภท</th>
              <th style={{ padding: "8px 4px" }}>บทบาท</th>
              <th style={{ padding: "8px 4px" }}>ปรากฏใน</th>
            </tr>
          </thead>
          <tbody>
            {characters.map((c) => (
              <tr key={c.id} style={{ borderBottom: "1px solid var(--border)" }}>
                <td style={{ padding: "8px 4px" }}>
                  <Link href={`/characters/${c.id}`}>{c.name}</Link>
                </td>
                <td style={{ padding: "8px 4px" }}>{TYPE_LABEL[c.type]}</td>
                <td style={{ padding: "8px 4px", color: "var(--muted)" }}>{c.role ?? "—"}</td>
                <td style={{ padding: "8px 4px", color: "var(--muted)" }}>
                  {c.appears_in.length ? c.appears_in.join(", ") : "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <section style={{ marginTop: 32 }}>
        <h2>สร้างตัวละครใหม่</h2>
        <CreateCharacterForm channelId={channel.id} />
      </section>
    </main>
  );
}
