if (-not (Test-Path ".\package.json")) {
  Write-Host "Jalankan script ini dari root proyek (folder yang berisi package.json)." -ForegroundColor Red
  exit 1
}

if (-not (Test-Path ".\src\components\Providers.tsx")) {
  Write-Host "src\components\Providers.tsx belum ada. Jalankan scaffold-step4.ps1 dulu." -ForegroundColor Red
  exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-SourceFile($relativePath, $content) {
  $fullPath = Join-Path (Get-Location) $relativePath
  $dir = Split-Path $fullPath -Parent
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [System.IO.File]::WriteAllText($fullPath, $content.Replace("`r`n", "`n"), $utf8)
  Write-Host "Dibuat: $relativePath" -ForegroundColor Green
}

if (Test-Path ".\src\app\page.tsx") {
  Remove-Item ".\src\app\page.tsx"
  Write-Host "Dihapus: src\app\page.tsx (bawaan)" -ForegroundColor Yellow
}

Write-SourceFile "src\app\layout.tsx" @'
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
'@

Write-SourceFile "src\features\auth\layouts\AuthLayout.tsx" @'
"use client";

import { useEffect, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { IconMessageCircle } from "@tabler/icons-react";
import { getAccessToken } from "@/helpers/apiHelper";

export default function AuthLayout({ children }: { children: ReactNode }) {
  const router = useRouter();

  useEffect(() => {
    if (getAccessToken()) router.replace("/");
  }, [router]);

  return (
    <div className="grid min-h-screen lg:grid-cols-[1.05fr_1fr]">
      <aside
        aria-label="Tentang aplikasi"
        className="hidden bg-indigo-950 p-12 text-white lg:flex lg:flex-col lg:justify-between"
      >
        <p className="flex items-center gap-3 text-2xl font-extrabold">
          <span className="grid size-11 place-items-center rounded-2xl bg-amber-300 text-indigo-950">
            <IconMessageCircle size={24} aria-hidden="true" />
          </span>
          Post<span className="text-amber-300">Kampus</span>
        </p>
        <p className="text-4xl font-extrabold leading-tight">
          Bagikan cerita, <span className="text-amber-300">dapatkan dukungan.</span>
        </p>
        <p className="text-sm text-indigo-200">Dibuat untuk praktikum PABWE 2026</p>
      </aside>

      <main className="flex items-center justify-center bg-stone-100 px-5 py-10">
        <div className="w-full max-w-md">{children}</div>
      </main>
    </div>
  );
}
'@

Write-SourceFile "src\features\auth\pages\LoginPage.tsx" @'
"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { IconEye, IconEyeOff, IconLoader2 } from "@tabler/icons-react";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import useInput from "@/hooks/useInput";
import { asyncLogin } from "../states/action";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const FIELD =
  "w-full rounded-2xl border border-stone-300 bg-stone-50 px-4 py-3 outline-none transition focus:border-indigo-600 focus:ring-4 focus:ring-indigo-100";

export default function LoginPage() {
  const dispatch = useAppDispatch();
  const router = useRouter();
  const submitting = useAppSelector((state) => state.auth.isAuthLogin);
  const email = useInput("");
  const password = useInput("");
  const [reveal, setReveal] = useState(false);
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const found: { email?: string; password?: string } = {};
    if (!EMAIL_PATTERN.test(email.value)) found.email = "Format email tidak valid";
    if (password.value.length < 6) found.password = "Kata sandi minimal 6 karakter";
    setErrors(found);
    if (Object.keys(found).length > 0) return;

    const ok = await dispatch(asyncLogin({ email: email.value, password: password.value })).unwrap();
    if (ok) router.replace("/");
  };

  return (
    <div className="rounded-[2rem] bg-white p-8 shadow-xl shadow-indigo-950/5 ring-1 ring-stone-200">
      <h1 className="text-3xl font-extrabold text-indigo-950">Masuk</h1>
      <p className="mt-2 text-sm text-stone-600">Lanjutkan untuk melihat dan membuat postingan.</p>

      <form onSubmit={handleSubmit} noValidate className="mt-8 space-y-5">
        <div>
          <label htmlFor="login-email" className="mb-1.5 block text-sm font-bold text-stone-700">
            Email
          </label>
          <input
            id="login-email"
            type="email"
            autoComplete="email"
            value={email.value}
            onChange={email.onChange}
            className={FIELD}
          />
          {errors.email && <p className="mt-1.5 text-sm font-medium text-rose-600">{errors.email}</p>}
        </div>

        <div>
          <label htmlFor="login-password" className="mb-1.5 block text-sm font-bold text-stone-700">
            Kata sandi
          </label>
          <div className="relative">
            <input
              id="login-password"
              type={reveal ? "text" : "password"}
              autoComplete="current-password"
              value={password.value}
              onChange={password.onChange}
              className={`${FIELD} pr-12`}
            />
            <button
              type="button"
              aria-label={reveal ? "Sembunyikan kata sandi" : "Tampilkan kata sandi"}
              onClick={() => setReveal((v) => !v)}
              className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-stone-600"
            >
              {reveal ? <IconEyeOff size={20} aria-hidden="true" /> : <IconEye size={20} aria-hidden="true" />}
            </button>
          </div>
          {errors.password && <p className="mt-1.5 text-sm font-medium text-rose-600">{errors.password}</p>}
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="flex w-full items-center justify-center gap-2 rounded-2xl bg-indigo-950 py-3.5 font-bold text-amber-300 transition hover:bg-indigo-900 disabled:opacity-60"
        >
          {submitting && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
          {submitting ? "Memproses…" : "Masuk"}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-stone-600">
        Belum punya akun?{" "}
        <Link href="/auth/register" className="font-bold text-indigo-700 hover:underline">
          Daftar sekarang
        </Link>
      </p>
    </div>
  );
}
'@

Write-SourceFile "src\features\auth\pages\RegisterPage.tsx" @'
"use client";

import { useState, type FormEvent, type InputHTMLAttributes } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { IconLoader2 } from "@tabler/icons-react";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import useInput from "@/hooks/useInput";
import { asyncRegister } from "../states/action";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const FIELD =
  "w-full rounded-2xl border border-stone-300 bg-stone-50 px-4 py-3 outline-none transition focus:border-indigo-600 focus:ring-4 focus:ring-indigo-100";

interface FieldProps extends InputHTMLAttributes<HTMLInputElement> {
  id: string;
  label: string;
  error?: string;
}

function Field({ id, label, error, ...rest }: FieldProps) {
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-sm font-bold text-stone-700">
        {label}
      </label>
      <input id={id} className={FIELD} {...rest} />
      {error && <p className="mt-1.5 text-sm font-medium text-rose-600">{error}</p>}
    </div>
  );
}

export default function RegisterPage() {
  const dispatch = useAppDispatch();
  const router = useRouter();
  const submitting = useAppSelector((state) => state.auth.isAuthRegister);
  const name = useInput("");
  const email = useInput("");
  const password = useInput("");
  const confirm = useInput("");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const found: Record<string, string> = {};
    if (name.value.trim().length < 3) found.name = "Nama minimal 3 karakter";
    if (!EMAIL_PATTERN.test(email.value)) found.email = "Format email tidak valid";
    if (password.value.length < 6) found.password = "Kata sandi minimal 6 karakter";
    if (confirm.value !== password.value) found.confirm = "Konfirmasi kata sandi tidak sama";
    setErrors(found);
    if (Object.keys(found).length > 0) return;

    const ok = await dispatch(
      asyncRegister({ name: name.value.trim(), email: email.value, password: password.value }),
    ).unwrap();
    if (ok) router.push("/auth/login");
  };

  return (
    <div className="rounded-[2rem] bg-white p-8 shadow-xl shadow-indigo-950/5 ring-1 ring-stone-200">
      <h1 className="text-3xl font-extrabold text-indigo-950">Buat akun</h1>
      <p className="mt-2 text-sm text-stone-600">Gabung untuk membagikan postingan pertamamu.</p>

      <form onSubmit={handleSubmit} noValidate className="mt-8 space-y-4">
        <Field id="reg-name" label="Nama lengkap" value={name.value} onChange={name.onChange} error={errors.name} />
        <Field id="reg-email" label="Email" type="email" value={email.value} onChange={email.onChange} error={errors.email} />
        <Field id="reg-password" label="Kata sandi" type="password" value={password.value} onChange={password.onChange} error={errors.password} />
        <Field id="reg-confirm" label="Ulangi kata sandi" type="password" value={confirm.value} onChange={confirm.onChange} error={errors.confirm} />

        <button
          type="submit"
          disabled={submitting}
          className="mt-2 flex w-full items-center justify-center gap-2 rounded-2xl bg-indigo-950 py-3.5 font-bold text-amber-300 transition hover:bg-indigo-900 disabled:opacity-60"
        >
          {submitting && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
          {submitting ? "Memproses…" : "Daftar"}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-stone-600">
        Sudah punya akun?{" "}
        <Link href="/auth/login" className="font-bold text-indigo-700 hover:underline">
          Masuk
        </Link>
      </p>
    </div>
  );
}
'@

Write-SourceFile "src\app\auth\layout.tsx" @'
import type { ReactNode } from "react";
import AuthLayout from "@/features/auth/layouts/AuthLayout";

export default function Layout({ children }: { children: ReactNode }) {
  return <AuthLayout>{children}</AuthLayout>;
}
'@

Write-SourceFile "src\app\auth\login\page.tsx" @'
import LoginPage from "@/features/auth/pages/LoginPage";

export default function Page() {
  return <LoginPage />;
}
'@

Write-SourceFile "src\app\auth\register\page.tsx" @'
import RegisterPage from "@/features/auth/pages/RegisterPage";

export default function Page() {
  return <RegisterPage />;
}
'@

Write-SourceFile "src\app\(dashboard)\page.tsx" @'
export default function Page() {
  return (
    <main className="p-10">
      <h1 className="text-2xl font-extrabold">Dashboard (sementara)</h1>
    </main>
  );
}
'@

Write-Host ""
Write-Host "Langkah 5 selesai. Jalankan: npm.cmd run dev" -ForegroundColor Cyan