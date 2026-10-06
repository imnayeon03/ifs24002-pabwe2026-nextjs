if (-not (Test-Path ".\package.json")) {
  Write-Host "Jalankan dari root proyek (folder yang berisi package.json)." -ForegroundColor Red
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

# ---------- Bersihkan bawaan ----------
if (Test-Path ".\src\app\page.tsx") { Remove-Item ".\src\app\page.tsx" }

# ---------- .env ----------
$envText = "NEXT_PUBLIC_DELCOM_BASEURL=https://open-api.delcom.org/api/v1`nAPP_PORT=3000`n"
[System.IO.File]::WriteAllText((Join-Path (Get-Location) ".env"), $envText, $utf8)
[System.IO.File]::WriteAllText((Join-Path (Get-Location) ".env.example"), $envText, $utf8)
Write-Host "Dibuat: .env dan .env.example" -ForegroundColor Green

# .env.example harus ikut di-commit
if (Test-Path ".gitignore") {
  $gi = Get-Content ".gitignore" -Raw
  if ($gi -notmatch "!\.env\.example") {
    Add-Content ".gitignore" "`n!.env.example"
  }
}

# ---------- package.json scripts ----------
$pkgPath = Join-Path (Get-Location) "package.json"
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
$newScripts = [ordered]@{
  "dev"           = "next dev"
  "dev:server"    = "bun src/server.ts"
  "build"         = "next build"
  "start"         = "next start"
  "start:server"  = "bun src/server.ts --prod"
  "test"          = "vitest run"
  "test:coverage" = "vitest run --coverage"
}
foreach ($key in $newScripts.Keys) {
  $pkg.scripts | Add-Member -NotePropertyName $key -NotePropertyValue $newScripts[$key] -Force
}
[System.IO.File]::WriteAllText($pkgPath, ($pkg | ConvertTo-Json -Depth 10), $utf8)
Write-Host "Diperbarui: package.json (scripts)" -ForegroundColor Green

# ---------- Konfigurasi ----------
Write-SourceFile "src\app\globals.css" @'
@import "tailwindcss";

@theme inline {
  --font-sans: var(--font-manrope), system-ui, sans-serif;
}

body {
  @apply bg-stone-100 text-stone-900 antialiased;
}
'@

Write-SourceFile "next.config.ts" @'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  compress: true,
  poweredByHeader: false,
};

export default nextConfig;
'@

Write-SourceFile "src\server.ts" @'
import { createServer } from "node:http";
import next from "next";

const dev = !process.argv.includes("--prod");
const port = Number(process.env.APP_PORT ?? 3000);

const app = next({ dev });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  createServer((req, res) => handle(req, res)).listen(port, () => {
    console.log(`> Server siap di http://localhost:${port} (${dev ? "dev" : "production"})`);
  });
});
'@

Write-SourceFile "src\lib\config.ts" @'
export const DELCOM_BASEURL =
  process.env.NEXT_PUBLIC_DELCOM_BASEURL ?? "https://open-api.delcom.org/api/v1";

export const APP_PORT = Number(process.env.APP_PORT ?? 3000);
'@

# ---------- Types ----------
Write-SourceFile "src\types\index.ts" @'
export interface ApiResult<T = unknown> {
  status: "success" | "fail";
  message: string;
  data?: T;
}

export interface User {
  id: number;
  name: string;
  email: string;
  photo?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface PostAuthor {
  name: string;
  photo: string | null;
}

export interface PostComment {
  id: number;
  comment: string;
  created_at: string;
  updated_at: string;
}

export interface Post {
  id: number;
  user_id: number;
  cover: string | null;
  description: string;
  created_at: string;
  updated_at: string;
  author: PostAuthor;
  likes: number[];
  comments: number[] | PostComment[];
  my_comment?: PostComment | null;
}
'@

Write-SourceFile "src\types\action.ts" @'
export interface LoginPayload {
  email: string;
  password: string;
}

export interface RegisterPayload extends LoginPayload {
  name: string;
}
'@

# ---------- Helpers ----------
Write-SourceFile "src\helpers\apiHelper.ts" @'
import { DELCOM_BASEURL } from "@/lib/config";
import type { ApiResult } from "@/types";

const TOKEN_KEY = "token";

export const getAccessToken = (): string | null =>
  typeof window === "undefined" ? null : localStorage.getItem(TOKEN_KEY);

export const putAccessToken = (token: string): void => localStorage.setItem(TOKEN_KEY, token);

export const removeAccessToken = (): void => localStorage.removeItem(TOKEN_KEY);

type Query = Record<string, string | number | undefined>;

interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "DELETE";
  query?: Query;
  body?: unknown;
  auth?: boolean;
}

export async function apiFetch<T = unknown>(
  path: string,
  { method = "GET", query, body, auth = true }: RequestOptions = {},
): Promise<ApiResult<T>> {
  const url = new URL(`${DELCOM_BASEURL}${path}`);
  Object.entries(query ?? {}).forEach(([key, value]) => {
    if (value !== undefined) url.searchParams.set(key, String(value));
  });

  const headers: Record<string, string> = { Accept: "application/json" };
  const token = getAccessToken();
  if (auth && token) headers.Authorization = `Bearer ${token}`;

  let payload: BodyInit | undefined;
  if (body instanceof FormData) {
    payload = body;
  } else if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    payload = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, { method, headers, body: payload });
    return (await response.json()) as ApiResult<T>;
  } catch {
    return { status: "fail", message: "Tidak dapat terhubung ke server" };
  }
}
'@

Write-SourceFile "src\helpers\toolsHelper.ts" @'
import Swal from "sweetalert2";
import { DELCOM_BASEURL } from "@/lib/config";

export const showSuccessDialog = (message: string) =>
  Swal.fire({ icon: "success", title: "Berhasil", text: message, confirmButtonColor: "#1e1b4b" });

export const showErrorDialog = (message: string) =>
  Swal.fire({ icon: "error", title: "Gagal", text: message, confirmButtonColor: "#1e1b4b" });

export const showWarningDialog = (message: string) =>
  Swal.fire({ icon: "warning", title: "Perhatian", text: message, confirmButtonColor: "#1e1b4b" });

export const showConfirmDialog = async (title: string, text: string): Promise<boolean> => {
  const result = await Swal.fire({
    icon: "question",
    title,
    text,
    showCancelButton: true,
    confirmButtonText: "Ya",
    cancelButtonText: "Batal",
    confirmButtonColor: "#1e1b4b",
  });
  return result.isConfirmed;
};

export const formatDate = (value: string): string =>
  new Date(value).toLocaleString("id-ID", { dateStyle: "long", timeStyle: "short" });

export const resolveMediaUrl = (path?: string | null): string | null => {
  if (!path) return null;
  if (/^https?:\/\//.test(path)) return path;
  return `${new URL(DELCOM_BASEURL).origin}/${path.replace(/^\//, "")}`;
};
'@

# ---------- Hooks ----------
Write-SourceFile "src\hooks\useInput.ts" @'
import { useState, type ChangeEvent } from "react";

export default function useInput(initialValue = "") {
  const [value, setValue] = useState(initialValue);

  const onChange = (
    event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>,
  ) => setValue(event.target.value);

  return { value, onChange, setValue };
}
'@

Write-SourceFile "src\hooks\redux.ts" @'
import { useDispatch, useSelector, type TypedUseSelectorHook } from "react-redux";
import type { AppDispatch, RootState } from "@/store";

export const useAppDispatch: () => AppDispatch = useDispatch;
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
'@

# ---------- Auth: API dan state ----------
Write-SourceFile "src\features\auth\api\authApi.ts" @'
import { apiFetch } from "@/helpers/apiHelper";
import type { LoginPayload, RegisterPayload } from "@/types/action";
import type { User } from "@/types";

export const login = (payload: LoginPayload) =>
  apiFetch<{ user: User; token: string }>("/auth/login", {
    method: "POST",
    body: payload,
    auth: false,
  });

export const register = (payload: RegisterPayload) =>
  apiFetch("/auth/register", { method: "POST", body: payload, auth: false });

export const logout = () => apiFetch("/auth/logout", { method: "POST" });
'@

Write-SourceFile "src\features\auth\states\action.ts" @'
import { createAsyncThunk } from "@reduxjs/toolkit";
import { putAccessToken, removeAccessToken } from "@/helpers/apiHelper";
import { showErrorDialog, showSuccessDialog } from "@/helpers/toolsHelper";
import type { LoginPayload, RegisterPayload } from "@/types/action";
import * as authApi from "../api/authApi";

export const asyncLogin = createAsyncThunk("auth/login", async (payload: LoginPayload) => {
  const result = await authApi.login(payload);
  if (result.status !== "success" || !result.data) {
    void showErrorDialog(result.message);
    return false;
  }
  putAccessToken(result.data.token);
  return true;
});

export const asyncRegister = createAsyncThunk("auth/register", async (payload: RegisterPayload) => {
  const result = await authApi.register(payload);
  if (result.status !== "success") {
    void showErrorDialog(result.message);
    return false;
  }
  void showSuccessDialog(result.message);
  return true;
});

export const asyncLogout = createAsyncThunk("auth/logout", async () => {
  await authApi.logout();
  removeAccessToken();
  return true;
});
'@

Write-SourceFile "src\features\auth\states\reducer.ts" @'
import { createSlice, isAnyOf } from "@reduxjs/toolkit";
import { asyncLogin, asyncLogout, asyncRegister } from "./action";

const initialState = {
  isAuthLogin: false,
  isAuthRegister: false,
  isAuthLogout: false,
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(asyncLogin.pending, (state) => {
        state.isAuthLogin = true;
      })
      .addCase(asyncRegister.pending, (state) => {
        state.isAuthRegister = true;
      })
      .addCase(asyncLogout.pending, (state) => {
        state.isAuthLogout = true;
      })
      .addMatcher(isAnyOf(asyncLogin.fulfilled, asyncLogin.rejected), (state) => {
        state.isAuthLogin = false;
      })
      .addMatcher(isAnyOf(asyncRegister.fulfilled, asyncRegister.rejected), (state) => {
        state.isAuthRegister = false;
      })
      .addMatcher(isAnyOf(asyncLogout.fulfilled, asyncLogout.rejected), (state) => {
        state.isAuthLogout = false;
      });
  },
});

export default authSlice.reducer;
'@

# ---------- Store dan Providers ----------
Write-SourceFile "src\store.ts" @'
import { configureStore } from "@reduxjs/toolkit";
import authReducer from "@/features/auth/states/reducer";

const store = configureStore({
  reducer: {
    auth: authReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export default store;
'@

Write-SourceFile "src\components\Providers.tsx" @'
"use client";

import type { ReactNode } from "react";
import { Provider } from "react-redux";
import store from "@/store";

export default function Providers({ children }: { children: ReactNode }) {
  return <Provider store={store}>{children}</Provider>;
}
'@

# ---------- Root layout ----------
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

# ---------- Auth: layout dan halaman ----------
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

# ---------- Rute ----------
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
Write-Host "Selesai. Jalankan: npm.cmd run dev" -ForegroundColor Cyan