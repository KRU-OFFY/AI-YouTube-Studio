import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import {
  EditEpisodeForm,
  TransitionControls,
  type PillarOption,
} from "@/components/EpisodeForms";
import { STATUS_LABEL, type EpisodeStatus } from "@/lib/episode/validation";
import {
  EpisodeCharacters,
  type CharacterOption,
} from "@/components/EpisodeCharacters";

export const dynamic = "force-dynamic";

type Episode = {
  id: string;
  channel_id: string;
  title: string;
  status: EpisodeStatus;
  script: string | null;
  pillar_id: string | null;
  seed_data: unknown;
};

export default async function EpisodeDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: epData } = await supabase
    .from("episodes")
    .select("id, channel_id, title, status, script, pillar_id, seed_data")
    .eq("id", id)
    .maybeSingle();
  if (!epData) notFound();
  const episode = epData as Episode;

  const { data: chData } = await supabase
    .from("channels")
    .select("id, name")
    .eq("id", episode.channel_id)
    .maybeSingle();
  const channel = (chData ?? { id: episode.channel_id, name: "channel" }) as {
    id: string;
    name: string;
  };

  const { data: pillarsData } = await supabase
    .from("pillars")
    .select("id, name")
    .eq("channel_id", episode.channel_id)
    .order("name");
  const pillars = (pillarsData ?? []) as PillarOption[];

  // ตัวละคร (m2m): ผูกแล้ว vs ตัวเลือกที่เหลือ (channel เดียวกัน)
  const { data: charData } = await supabase
    .from("characters")
    .select("id, name")
    .eq("channel_id", episode.channel_id)
    .order("name");
  const allChars = (charData ?? []) as CharacterOption[];
  const { data: linkData } = await supabase
    .from("episode_characters")
    .select("character_id")
    .eq("episode_id", episode.id);
  const linkedIds = new Set(
    ((linkData ?? []) as { character_id: string }[]).map((r) => r.character_id),
  );
  const linkedChars = allChars.filter((c) => linkedIds.has(c.id));
  const availableChars = allChars.filter((c) => !linkedIds.has(c.id));

  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href={`/channels/${channel.id}/episodes`}>← กลับรายการตอน ({channel.name})</Link>
      </p>
      <h1>{episode.title}</h1>
      <p style={{ color: "var(--muted)" }}>
        สถานะ: <strong>{STATUS_LABEL[episode.status]}</strong>
      </p>

      <section style={{ marginTop: 24 }}>
        <h2>เปลี่ยนสถานะ</h2>
        <TransitionControls episodeId={episode.id} status={episode.status} />
      </section>

      <section style={{ marginTop: 32 }}>
        <h2>ตัวละครในตอน</h2>
        <EpisodeCharacters
          episodeId={episode.id}
          linked={linkedChars}
          available={availableChars}
        />
      </section>

      <section style={{ marginTop: 32 }}>
        <h2>แก้ไขตอน</h2>
        <EditEpisodeForm
          episode={{
            id: episode.id,
            title: episode.title,
            script: episode.script,
            pillar_id: episode.pillar_id,
          }}
          pillars={pillars}
        />
      </section>

      {episode.seed_data != null &&
        Object.keys(episode.seed_data as Record<string, unknown>).length > 0 && (
          <section style={{ marginTop: 32 }}>
            <h2>seed data</h2>
            <pre
              style={{
                background: "var(--surface, #1113)",
                padding: 12,
                borderRadius: 8,
                overflowX: "auto",
                fontSize: 13,
              }}
            >
              {JSON.stringify(episode.seed_data, null, 2)}
            </pre>
          </section>
        )}
    </main>
  );
}
