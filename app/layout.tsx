import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "TOFFY AI YouTube Studio",
  description: "ระบบผลิตคอนเทนต์ YouTube เด็กภาษาไทยแบรนด์ปุยฝัน (Puifun)",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="th">
      <body>{children}</body>
    </html>
  );
}
