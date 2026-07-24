import Link from "next/link";
import { AuthForm } from "@/components/AuthForm";
import { login } from "@/lib/auth/actions";

export const metadata = { title: "เข้าสู่ระบบ — TOFFY" };

export default function LoginPage() {
  return (
    <main className="auth-page">
      <h1>เข้าสู่ระบบ</h1>
      <p className="auth-sub">TOFFY AI YouTube Studio · ปุยฝัน</p>
      <AuthForm
        action={login}
        submitLabel="เข้าสู่ระบบ"
        footer={
          <>
            ยังไม่มีบัญชี? <Link href="/signup">สมัครสมาชิก</Link>
          </>
        }
      />
    </main>
  );
}
