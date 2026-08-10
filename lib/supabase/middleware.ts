import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

type CookieToSet = { name: string; value: string; options: CookieOptions };

// เส้นทางที่ต้องล็อกอินก่อนถึงจะเข้าได้
const PROTECTED_PREFIXES = ["/dashboard", "/workspaces", "/channels", "/episodes", "/assets", "/characters"];
// เส้นทางสำหรับผู้ที่ยังไม่ล็อกอิน (ถ้าล็อกอินแล้วเข้ามาจะเด้งไป dashboard)
const AUTH_ROUTES = ["/login", "/signup"];

// refresh session ทุก request + บังคับสิทธิ์เข้าถึงหน้า (app) ที่ระดับ middleware
export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });
  const path = request.nextUrl.pathname;
  const isProtected = PROTECTED_PREFIXES.some((p) => path.startsWith(p));

  // Allow public pages to load before the first Supabase setup. Without this
  // guard, createServerClient throws for every route when deployment secrets
  // have not been configured yet.
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    if (isProtected) {
      const loginUrl = request.nextUrl.clone();
      loginUrl.pathname = "/login";
      loginUrl.searchParams.set("redirectedFrom", path);
      loginUrl.searchParams.set("configuration", "missing");
      return NextResponse.redirect(loginUrl);
    }
    return response;
  }

  const supabase = createServerClient(
    url,
    anonKey,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // ตรวจ user ฝั่ง server (ห้ามเชื่อ getSession ฝั่ง client อย่างเดียว)
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const isAuthRoute = AUTH_ROUTES.includes(path);

  if (!user && isProtected) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("redirectedFrom", path);
    return NextResponse.redirect(url);
  }

  if (user && isAuthRoute) {
    const url = request.nextUrl.clone();
    url.pathname = "/dashboard";
    return NextResponse.redirect(url);
  }

  return response;
}
