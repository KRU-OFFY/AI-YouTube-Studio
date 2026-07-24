import { createSupabaseServerClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

type ConnectionStatus =
  | { state: "missing-env" }
  | { state: "ok"; url: string }
  | { state: "error"; message: string };

async function checkSupabase(): Promise<ConnectionStatus> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return { state: "missing-env" };
  try {
    const supabase = createSupabaseServerClient();
    const { error } = await supabase.from("content_pillars").select("id").limit(1);
    if (error && !/relation .* does not exist/i.test(error.message)) {
      return { state: "error", message: error.message };
    }
    return { state: "ok", url };
  } catch (err) {
    return { state: "error", message: err instanceof Error ? err.message : String(err) };
  }
}

export default async function DashboardPage() {
  const status = await checkSupabase();

  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "48px 24px" }}>
      <h1>Dashboard</h1>
      <p style={{ color: "var(--muted)" }}>
        โปรเจกต์: <strong>TOFFY AI YouTube Studio</strong> · แบรนด์: ปุยฝัน (Puifun)
      </p>

      <section style={{ marginTop: 32 }}>
        <h2 style={{ marginBottom: 8 }}>Supabase connection</h2>
        {status.state === "missing-env" && (
          <p style={{ color: "var(--warn)" }}>
            ยังไม่พบค่า <code>NEXT_PUBLIC_SUPABASE_URL</code> /{" "}
            <code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code> — คัดลอก{" "}
            <code>.env.example</code> เป็น <code>.env.local</code> แล้วกรอกค่าจาก
            Supabase dashboard
          </p>
        )}
        {status.state === "ok" && (
          <p style={{ color: "var(--ok)" }}>เชื่อมต่อ Supabase สำเร็จ · {status.url}</p>
        )}
        {status.state === "error" && (
          <p style={{ color: "var(--err)" }}>
            เชื่อมต่อ Supabase ไม่สำเร็จ: {status.message}
          </p>
        )}
      </section>

      <section style={{ marginTop: 32 }}>
        <h2 style={{ marginBottom: 8 }}>ขั้นตอนถัดไป</h2>
        <ol>
          <li>สร้างโปรเจกต์ใน Supabase แล้วเอาค่าไปใส่ใน <code>.env.local</code></li>
          <li>รัน migration ใน <code>supabase/migrations/</code></li>
          <li>ทำหน้าจัดการ Episodes / Characters เป็นเฟสถัดไป</li>
        </ol>
      </section>
    </main>
  );
}
