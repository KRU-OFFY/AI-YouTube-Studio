"use server";

import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { validateEmail, validatePassword } from "@/lib/auth/validation";

export type AuthState = {
  error: string | null;
  message?: string | null;
};

// ล็อกอิน — error รวมเป็นข้อความเดียวเสมอ เพื่อกัน user enumeration
export async function login(
  _prev: AuthState,
  formData: FormData,
): Promise<AuthState> {
  const email = String(formData.get("email") ?? "");
  const password = String(formData.get("password") ?? "");

  const validationError = validateEmail(email) ?? validatePassword(password);
  if (validationError) return { error: validationError };

  const supabase = createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  // ไม่แยกว่า "ไม่พบอีเมล" หรือ "รหัสผ่านผิด" — ตอบรวมกันเสมอ
  if (error) return { error: "อีเมลหรือรหัสผ่านไม่ถูกต้อง" };

  redirect("/dashboard");
}

// สมัครสมาชิก
export async function signup(
  _prev: AuthState,
  formData: FormData,
): Promise<AuthState> {
  const email = String(formData.get("email") ?? "");
  const password = String(formData.get("password") ?? "");

  const validationError = validateEmail(email) ?? validatePassword(password);
  if (validationError) return { error: validationError };

  const supabase = createSupabaseServerClient();
  const { data, error } = await supabase.auth.signUp({ email, password });

  if (error) return { error: error.message };

  // ถ้าโปรเจกต์เปิด email confirmation จะยังไม่มี session ทันที
  if (!data.session) {
    return {
      error: null,
      message: "สมัครสำเร็จ! กรุณาตรวจอีเมลเพื่อยืนยันบัญชี แล้วจึงเข้าสู่ระบบ",
    };
  }

  redirect("/dashboard");
}

// ออกจากระบบ
export async function logout(): Promise<void> {
  const supabase = createSupabaseServerClient();
  await supabase.auth.signOut();
  redirect("/login");
}
