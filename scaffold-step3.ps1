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

# Pindahkan file dari kumpulan kode lain ke backup (tidak dihapus)
New-Item -ItemType Directory -Force -Path ".\backup-lama" | Out-Null
$konflik = @(
  "src\store",
  "src\features\posts",
  "src\components\AuthGuard.tsx",
  "src\components\Navbar.tsx",
  "src\__tests__",
  "src\global.d.ts"
)
foreach ($item in $konflik) {
  if (Test-Path ".\$item") {
    $nama = $item -replace '[\\/]', '_'
    Move-Item ".\$item" ".\backup-lama\$nama" -Force
    Write-Host "Dipindah ke backup-lama: $item" -ForegroundColor Yellow
  }
}

Write-SourceFile "src\lib\config.ts" @'
export const DELCOM_BASEURL =
  process.env.NEXT_PUBLIC_DELCOM_BASEURL ?? "https://open-api.delcom.org/api/v1";

export const APP_PORT = Number(process.env.APP_PORT ?? 3000);
'@

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

Write-Host ""
Write-Host "Selesai. Sekarang jalankan scaffold-step4.ps1 lalu scaffold-step5.ps1." -ForegroundColor Cyan