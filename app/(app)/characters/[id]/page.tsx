import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import {
  EditCharacterForm,
  type CharacterDefaults,
} from "@/components/CharacterForms";

export const dynamic = "force-dynamic";

type Character = CharacterDefaults & { id: string; channel_id: string };

export default async function CharacterDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const supabase = createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data } = await supabase
    .from("characters")
    .select(
      "id, channel_id, name, slug, type, role, species, description, image_prompt, anchor_image_url, appearance, voice, personality, forbidden, appears_in",
    )
    .eq("id", params.id)
    .maybeSingle();
  if (!data) notFound();
  const c = data as Character;

  const { data: chData } = await supabase
    .from("channels")
    .select("id, name")
    .eq("id", c.channel_id)
    .maybeSingle();
  const channel = (chData ?? { id: c.channel_id, name: "channel" }) as {
    id: string;
    name: string;
  };

  return (
    <main style={{ maxWidth: 640, margin: "0 auto", padding: "48px 24px" }}>
      <p style={{ marginBottom: 24 }}>
        <Link href={`/channels/${channel.id}/characters`}>← กลับรายการตัวละคร ({channel.name})</Link>
      </p>
      <h1>{c.name}</h1>
      <section style={{ marginTop: 24 }}>
        <h2>แก้ไขตัวละคร</h2>
        <EditCharacterForm
          characterId={c.id}
          defaults={{
            name: c.name,
            slug: c.slug,
            type: c.type,
            role: c.role,
            species: c.species,
            description: c.description,
            image_prompt: c.image_prompt,
            anchor_image_url: c.anchor_image_url,
            appearance: c.appearance,
            voice: c.voice,
            personality: c.personality,
            forbidden: c.forbidden,
            appears_in: c.appears_in,
          }}
        />
      </section>
    </main>
  );
}
