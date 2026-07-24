import Link from "next/link";
import { AuthForm } from "@/components/AuthForm";
import { signup } from "@/lib/auth/actions";

export const metadata = { title: "สมัครสมาชิก — TOFFY" };

export default function SignupPage() {
  return (
    <main className="auth-page">
      <h1>สมัครสมาชิก</h1>
      <p className="auth-sub">TOFFY AI YouTube Studio · ปุยฝัน</p>
      <AuthForm
        action={signup}
        submitLabel="สมัครสมาชิก"
        footer={
          <>
            มีบัญชีอยู่แล้ว? <Link href="/login">เข้าสู่ระบบ</Link>
          </>
        }
      />
    </main>
  );
}
