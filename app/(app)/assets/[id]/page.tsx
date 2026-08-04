import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import {
  EditAssetForm,
  type AssetDefaults,
  type EpisodeOption,
} from "@/components/AssetForms";

export const dynamic = "force-dynamic";

type Asset = {
  id: string;
  channel_id: string;
  episode_id: string | null;
  type: string;
  role: string | null;
  title: string | null;
  storage_path: string;
  source_tool: string | null;
};

type Rights = {
  tool_used: string;
  plan: string | null;
  model: string | null;
  prompt_used: string | null;
  source_url: string | null;
  license_note: string | null;
  exported_at: string;
};

function toDateInput(ts: string | null): string {
  if (!ts) return "";
  const d = new Date(ts);
  return Number.isNaN(d.getTime()) ? "" : d.toISOString().slice(0, 10);
}

export default async function AssetDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const supabase = createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: aData } = await supabase
    .from("assets")
    .select("id, channel_id, episode_id, type, role, title, storage_path, source_tool")
    .eq("id", params.id)
    .maybeSingle();
  if (!aData) notFound();
  const asset = aData as Asset;

  const { data: rData } = await supabase
    .from("rights_records")
    .select("tool_used, plan, model, prompt_used, source_url, license_note, exported_at")
    .eq("asset_id", asset.id)
    .maybeSingle();
  const rights = (rData ?? null) as Rights | null;

  const { data: chData } = await supabase
    .from("channels")
    .select("id, name")
    .eq("id", asset.channel_id)
    .maybeSingle();
  const channel = (chData ?? { id: asset.channel_id, name: "channel" }) as {
    id: string;
    name: string;
  };

  const { data: epData } = await supabase
    .from("episodes")
    .select("id, title")
    .eq("channel_id", asset.channel_id)
    .order("updated_at", { ascending: false });
  const episodes = (epData ?? []) as EpisodeOption[];

  const defaults: AssetDefaults = {
    type: asset.type,
    role: asset.role,
    title: asset.title,
    episode_id: asset.episode_id,
    storage_path: asset.storage_path,
    source_tool: asset.source_tool,
    tool_used: rights?.tool_used ?? "",
    plan: rights?.plan ?? null,
    model: rights?.model ?? null,
    prompt_used: rights?.prompt_used ?? null,
    source_url: rights?.source_url ?? null,
    license_note: rights?.license_note ?? null,
    exported_at: toDateInput(rights?.exported_at ?? null),
  };

  return (
    <main style={{ maxWidth: 640, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href={`/channels/${channel.id}/assets`}>← กลับรายการ asset ({channel.name})</Link>
      </p>
      <h1>{asset.title || "(asset ไม่มีชื่อ)"}</h1>
      {!rights && (
        <p role="alert" className="auth-error">
          ⚠️ asset นี้ไม่มี rights record — ผิดกติกา provenance (ควรมี 1:1)
        </p>
      )}

      <section style={{ marginTop: 24 }}>
        <h2>แก้ไข asset + rights</h2>
        <EditAssetForm assetId={asset.id} defaults={defaults} episodes={episodes} />
      </section>
    </main>
  );
}
