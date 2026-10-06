import type { Metadata } from "next";
import { Manrope } from "next/font/google";
import type { ReactNode } from "react";
import Providers from "@/components/Providers";
import "./globals.css";

const manrope = Manrope({ subsets: ["latin"], variable: "--font-manrope", display: "swap" });

export const metadata: Metadata = {
  title: "PostKampus | Postingan Kampus",
  description: "Aplikasi postingan: bagikan cerita, suka, dan komentar.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="id" className={manrope.variable}>
      <body className="min-h-screen font-sans">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}