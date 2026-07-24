import Link from "next/link";

export default function HomePage() {
  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "48px 24px" }}>
      <h1 style={{ fontSize: 36, marginBottom: 8 }}>
        TOFFY AI YouTube Studio
      </h1>
      <p style={{ color: "var(--muted)", marginTop: 0 }}>
        ระบบผลิตคอนเทนต์สำหรับช่อง <strong>ปุยฝัน (Puifun)</strong>
      </p>
      <p style={{ display: "flex", gap: 12 }}>
        <Link href="/login">เข้าสู่ระบบ</Link>
        <span style={{ color: "var(--muted)" }}>·</span>
        <Link href="/signup">สมัครสมาชิก</Link>
      </p>
    </main>
  );
}
