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

# ---------- Types (menambah payload profil dan kata sandi) ----------
Write-SourceFile "src\types\action.ts" @'
export interface LoginPayload {
  email: string;
  password: string;
}

export interface RegisterPayload extends LoginPayload {
  name: string;
}

export interface ProfilePayload {
  name: string;
  email: string;
}

export interface ChangePasswordPayload {
  password: string;
  new_password: string;
  new_password_confirmation: string;
}
'@

# ---------- Users: API ----------
Write-SourceFile "src\features\users\api\userApi.ts" @'
import { apiFetch } from "@/helpers/apiHelper";
import type { ChangePasswordPayload, ProfilePayload } from "@/types/action";
import type { User } from "@/types";

export const getUsers = () => apiFetch<{ users: User[] }>("/users");

export const getProfile = () => apiFetch<{ user: User }>("/users/me");

export const changeProfile = (payload: ProfilePayload) =>
  apiFetch<{ user: User }>("/users/me", { method: "PUT", body: payload });

export const changeProfilePhoto = (photo: File) => {
  const form = new FormData();
  form.append("photo", photo);
  return apiFetch("/users/me/photo", { method: "POST", body: form });
};

// Sesuai dokumentasi Delcom: PUT /users/password
export const changePassword = (payload: ChangePasswordPayload) =>
  apiFetch("/users/password", { method: "PUT", body: payload });
'@

# ---------- Users: state ----------
Write-SourceFile "src\features\users\states\action.ts" @'
import { createAsyncThunk } from "@reduxjs/toolkit";
import { showErrorDialog, showSuccessDialog } from "@/helpers/toolsHelper";
import type { ChangePasswordPayload, ProfilePayload } from "@/types/action";
import type { User } from "@/types";
import * as userApi from "../api/userApi";

export const asyncGetUsers = createAsyncThunk("users/getUsers", async (): Promise<User[]> => {
  const result = await userApi.getUsers();
  if (result.status !== "success" || !result.data) {
    void showErrorDialog(result.message);
    return [];
  }
  return result.data.users;
});

export const asyncGetProfile = createAsyncThunk("users/getProfile", async (): Promise<User | null> => {
  const result = await userApi.getProfile();
  if (result.status !== "success" || !result.data) return null;
  return result.data.user;
});

export const asyncChangeProfile = createAsyncThunk(
  "users/changeProfile",
  async (payload: ProfilePayload, { dispatch }) => {
    const result = await userApi.changeProfile(payload);
    if (result.status !== "success") {
      void showErrorDialog(result.message);
      return false;
    }
    void showSuccessDialog(result.message);
    await dispatch(asyncGetProfile());
    return true;
  },
);

export const asyncChangeProfilePhoto = createAsyncThunk(
  "users/changeProfilePhoto",
  async (photo: File, { dispatch }) => {
    const result = await userApi.changeProfilePhoto(photo);
    if (result.status !== "success") {
      void showErrorDialog(result.message);
      return false;
    }
    void showSuccessDialog(result.message);
    await dispatch(asyncGetProfile());
    return true;
  },
);

export const asyncChangeProfilePassword = createAsyncThunk(
  "users/changeProfilePassword",
  async (payload: ChangePasswordPayload) => {
    const result = await userApi.changePassword(payload);
    if (result.status !== "success") {
      void showErrorDialog(result.message);
      return false;
    }
    void showSuccessDialog(result.message);
    return true;
  },
);
'@

Write-SourceFile "src\features\users\states\reducer.ts" @'
import { createSlice, isAnyOf } from "@reduxjs/toolkit";
import type { User } from "@/types";
import {
  asyncChangeProfile,
  asyncChangeProfilePassword,
  asyncChangeProfilePhoto,
  asyncGetProfile,
  asyncGetUsers,
} from "./action";

interface UsersState {
  users: User[];
  profile: User | null;
  isUsers: boolean;
  isProfile: boolean;
  isChangeProfile: boolean;
  isChangeProfilePhoto: boolean;
  isChangeProfilePassword: boolean;
}

const initialState: UsersState = {
  users: [],
  profile: null,
  isUsers: false,
  isProfile: false,
  isChangeProfile: false,
  isChangeProfilePhoto: false,
  isChangeProfilePassword: false,
};

const usersSlice = createSlice({
  name: "users",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(asyncGetUsers.pending, (state) => {
        state.isUsers = true;
      })
      .addCase(asyncGetUsers.fulfilled, (state, action) => {
        state.users = action.payload;
        state.isUsers = false;
      })
      .addCase(asyncGetUsers.rejected, (state) => {
        state.isUsers = false;
      })
      .addCase(asyncGetProfile.pending, (state) => {
        state.isProfile = true;
      })
      .addCase(asyncGetProfile.fulfilled, (state, action) => {
        if (action.payload) state.profile = action.payload;
        state.isProfile = false;
      })
      .addCase(asyncGetProfile.rejected, (state) => {
        state.isProfile = false;
      })
      .addCase(asyncChangeProfile.pending, (state) => {
        state.isChangeProfile = true;
      })
      .addCase(asyncChangeProfilePhoto.pending, (state) => {
        state.isChangeProfilePhoto = true;
      })
      .addCase(asyncChangeProfilePassword.pending, (state) => {
        state.isChangeProfilePassword = true;
      })
      .addMatcher(isAnyOf(asyncChangeProfile.fulfilled, asyncChangeProfile.rejected), (state) => {
        state.isChangeProfile = false;
      })
      .addMatcher(isAnyOf(asyncChangeProfilePhoto.fulfilled, asyncChangeProfilePhoto.rejected), (state) => {
        state.isChangeProfilePhoto = false;
      })
      .addMatcher(
        isAnyOf(asyncChangeProfilePassword.fulfilled, asyncChangeProfilePassword.rejected),
        (state) => {
          state.isChangeProfilePassword = false;
        },
      );
  },
});

export default usersSlice.reducer;
'@

# ---------- Store (menambah slice users) ----------
Write-SourceFile "src\store.ts" @'
import { configureStore } from "@reduxjs/toolkit";
import authReducer from "@/features/auth/states/reducer";
import usersReducer from "@/features/users/states/reducer";

const store = configureStore({
  reducer: {
    auth: authReducer,
    users: usersReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export default store;
'@

# ---------- Komponen Avatar ----------
Write-SourceFile "src\components\Avatar.tsx" @'
import { resolveMediaUrl } from "@/helpers/toolsHelper";

interface AvatarProps {
  name: string;
  photo?: string | null;
  size?: number;
}

export default function Avatar({ name, photo, size = 44 }: AvatarProps) {
  const url = resolveMediaUrl(photo);
  const initial = name.trim().charAt(0).toUpperCase() || "?";

  if (url) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={url}
        alt={`Foto ${name}`}
        width={size}
        height={size}
        className="rounded-full bg-stone-200 object-cover"
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <span
      aria-hidden="true"
      className="grid place-items-center rounded-full bg-indigo-950 font-extrabold text-amber-300"
      style={{ width: size, height: size }}
    >
      {initial}
    </span>
  );
}
'@

# ---------- UsersPage ----------
Write-SourceFile "src\features\users\pages\UsersPage.tsx" @'
"use client";

import { useEffect } from "react";
import { IconLoader2, IconSearch } from "@tabler/icons-react";
import Avatar from "@/components/Avatar";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import useInput from "@/hooks/useInput";
import { asyncGetUsers } from "../states/action";

export default function UsersPage() {
  const dispatch = useAppDispatch();
  const { users, isUsers } = useAppSelector((state) => state.users);
  const keyword = useInput("");

  useEffect(() => {
    void dispatch(asyncGetUsers());
  }, [dispatch]);

  const needle = keyword.value.trim().toLowerCase();
  const visible = users.filter((user) => `${user.name} ${user.email}`.toLowerCase().includes(needle));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-indigo-950">Daftar pengguna</h1>
        <p className="mt-1 text-stone-600">Temukan pengguna yang terdaftar di aplikasi.</p>
      </div>

      <div className="relative">
        <IconSearch
          size={18}
          aria-hidden="true"
          className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-600"
        />
        <input
          type="search"
          aria-label="Cari pengguna"
          placeholder="Cari nama atau email…"
          value={keyword.value}
          onChange={keyword.onChange}
          className="w-full rounded-2xl border-0 bg-white py-3 pl-11 pr-4 outline-none ring-1 ring-stone-200 focus:ring-2 focus:ring-indigo-600"
        />
      </div>

      {isUsers && (
        <p role="status" className="flex items-center justify-center gap-2 py-10 text-stone-600">
          <IconLoader2 className="animate-spin" aria-hidden="true" /> Memuat pengguna…
        </p>
      )}

      {!isUsers && visible.length === 0 && (
        <p className="rounded-[1.75rem] border-2 border-dashed border-stone-300 py-12 text-center font-semibold text-stone-600">
          Tidak ada pengguna yang cocok.
        </p>
      )}

      {!isUsers && visible.length > 0 && (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {visible.map((user) => (
            <li
              key={user.id}
              className="flex items-center gap-4 rounded-[1.75rem] bg-white p-5 ring-1 ring-stone-200"
            >
              <Avatar name={user.name} photo={user.photo} />
              <div className="min-w-0">
                <p className="truncate font-bold text-indigo-950">{user.name}</p>
                <p className="truncate text-sm text-stone-600">{user.email}</p>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
'@

# ---------- ProfilePage ----------
Write-SourceFile "src\features\users\pages\ProfilePage.tsx" @'
"use client";

import { useEffect, useState, type FormEvent } from "react";
import { IconLoader2 } from "@tabler/icons-react";
import Avatar from "@/components/Avatar";
import { showWarningDialog } from "@/helpers/toolsHelper";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import useInput from "@/hooks/useInput";
import {
  asyncChangeProfile,
  asyncChangeProfilePassword,
  asyncChangeProfilePhoto,
  asyncGetProfile,
} from "../states/action";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const FIELD =
  "w-full rounded-2xl border border-stone-300 bg-stone-50 px-4 py-3 outline-none transition focus:border-indigo-600 focus:ring-4 focus:ring-indigo-100";
const BUTTON =
  "flex items-center justify-center gap-2 rounded-2xl bg-indigo-950 px-6 py-3 font-bold text-amber-300 transition hover:bg-indigo-900 disabled:opacity-60";

export default function ProfilePage() {
  const dispatch = useAppDispatch();
  const { profile, isProfile, isChangeProfile, isChangeProfilePhoto, isChangeProfilePassword } =
    useAppSelector((state) => state.users);

  const nameInput = useInput("");
  const emailInput = useInput("");
  const setName = nameInput.setValue;
  const setEmail = emailInput.setValue;

  const currentPassword = useInput("");
  const newPassword = useInput("");
  const confirmPassword = useInput("");
  const [photo, setPhoto] = useState<File | null>(null);
  const [profileErrors, setProfileErrors] = useState<Record<string, string>>({});
  const [passwordErrors, setPasswordErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    void dispatch(asyncGetProfile());
  }, [dispatch]);

  useEffect(() => {
    if (profile) {
      setName(profile.name);
      setEmail(profile.email);
    }
  }, [profile, setName, setEmail]);

  const submitProfile = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const found: Record<string, string> = {};
    if (nameInput.value.trim().length < 3) found.name = "Nama minimal 3 karakter";
    if (!EMAIL_PATTERN.test(emailInput.value)) found.email = "Format email tidak valid";
    setProfileErrors(found);
    if (Object.keys(found).length > 0) return;
    await dispatch(asyncChangeProfile({ name: nameInput.value.trim(), email: emailInput.value }));
  };

  const submitPhoto = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!photo) {
      void showWarningDialog("Pilih foto terlebih dahulu");
      return;
    }
    const ok = await dispatch(asyncChangeProfilePhoto(photo)).unwrap();
    if (ok) setPhoto(null);
  };

  const submitPassword = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const found: Record<string, string> = {};
    if (currentPassword.value.length < 6) found.current = "Kata sandi saat ini minimal 6 karakter";
    if (newPassword.value.length < 6) found.next = "Kata sandi baru minimal 6 karakter";
    if (confirmPassword.value !== newPassword.value) found.confirm = "Konfirmasi tidak sama";
    setPasswordErrors(found);
    if (Object.keys(found).length > 0) return;

    const ok = await dispatch(
      asyncChangeProfilePassword({
        password: currentPassword.value,
        new_password: newPassword.value,
        new_password_confirmation: confirmPassword.value,
      }),
    ).unwrap();
    if (ok) {
      currentPassword.setValue("");
      newPassword.setValue("");
      confirmPassword.setValue("");
    }
  };

  if (isProfile && !profile) {
    return (
      <div role="status" className="py-20 text-center text-stone-600">
        <h1 className="sr-only">Profil saya</h1>
        <p>Memuat profil…</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Avatar name={profile?.name ?? ""} photo={profile?.photo} size={72} />
        <div>
          <h1 className="text-3xl font-extrabold text-indigo-950">Profil saya</h1>
          <p className="text-stone-600">{profile?.email}</p>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <section aria-labelledby="judul-data" className="rounded-[2rem] bg-white p-7 ring-1 ring-stone-200">
          <h2 id="judul-data" className="text-xl font-extrabold text-indigo-950">Data akun</h2>
          <form onSubmit={submitProfile} noValidate className="mt-5 space-y-4">
            <div>
              <label htmlFor="profile-name" className="mb-1.5 block text-sm font-bold text-stone-700">Nama</label>
              <input id="profile-name" className={FIELD} value={nameInput.value} onChange={nameInput.onChange} />
              {profileErrors.name && <p className="mt-1.5 text-sm font-medium text-rose-600">{profileErrors.name}</p>}
            </div>
            <div>
              <label htmlFor="profile-email" className="mb-1.5 block text-sm font-bold text-stone-700">Email</label>
              <input id="profile-email" type="email" className={FIELD} value={emailInput.value} onChange={emailInput.onChange} />
              {profileErrors.email && <p className="mt-1.5 text-sm font-medium text-rose-600">{profileErrors.email}</p>}
            </div>
            <button type="submit" disabled={isChangeProfile} className={BUTTON}>
              {isChangeProfile && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
              Simpan perubahan
            </button>
          </form>
        </section>

        <section aria-labelledby="judul-foto" className="rounded-[2rem] bg-white p-7 ring-1 ring-stone-200">
          <h2 id="judul-foto" className="text-xl font-extrabold text-indigo-950">Foto profil</h2>
          <form onSubmit={submitPhoto} className="mt-5 space-y-4">
            <div>
              <label htmlFor="profile-photo" className="mb-1.5 block text-sm font-bold text-stone-700">Pilih foto baru</label>
              <input
                id="profile-photo"
                type="file"
                accept="image/*"
                onChange={(e) => setPhoto(e.target.files?.[0] ?? null)}
                className="w-full text-sm file:mr-3 file:rounded-lg file:border-0 file:bg-amber-100 file:px-4 file:py-2 file:font-bold file:text-amber-900"
              />
            </div>
            <button type="submit" disabled={isChangeProfilePhoto} className={BUTTON}>
              {isChangeProfilePhoto && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
              Unggah foto
            </button>
          </form>
        </section>

        <section aria-labelledby="judul-sandi" className="rounded-[2rem] bg-white p-7 ring-1 ring-stone-200 lg:col-span-2">
          <h2 id="judul-sandi" className="text-xl font-extrabold text-indigo-950">Ubah kata sandi</h2>
          <form onSubmit={submitPassword} noValidate className="mt-5 grid gap-4 md:grid-cols-3">
            <div>
              <label htmlFor="pw-current" className="mb-1.5 block text-sm font-bold text-stone-700">Kata sandi saat ini</label>
              <input id="pw-current" type="password" autoComplete="current-password" className={FIELD} value={currentPassword.value} onChange={currentPassword.onChange} />
              {passwordErrors.current && <p className="mt-1.5 text-sm font-medium text-rose-600">{passwordErrors.current}</p>}
            </div>
            <div>
              <label htmlFor="pw-new" className="mb-1.5 block text-sm font-bold text-stone-700">Kata sandi baru</label>
              <input id="pw-new" type="password" autoComplete="new-password" className={FIELD} value={newPassword.value} onChange={newPassword.onChange} />
              {passwordErrors.next && <p className="mt-1.5 text-sm font-medium text-rose-600">{passwordErrors.next}</p>}
            </div>
            <div>
              <label htmlFor="pw-confirm" className="mb-1.5 block text-sm font-bold text-stone-700">Ulangi kata sandi baru</label>
              <input id="pw-confirm" type="password" autoComplete="new-password" className={FIELD} value={confirmPassword.value} onChange={confirmPassword.onChange} />
              {passwordErrors.confirm && <p className="mt-1.5 text-sm font-medium text-rose-600">{passwordErrors.confirm}</p>}
            </div>
            <div className="md:col-span-3">
              <button type="submit" disabled={isChangeProfilePassword} className={BUTTON}>
                {isChangeProfilePassword && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
                Ubah kata sandi
              </button>
            </div>
          </form>
        </section>
      </div>
    </div>
  );
}
'@

# ---------- Rute dashboard ----------
Write-SourceFile "src\app\(dashboard)\users\page.tsx" @'
import UsersPage from "@/features/users/pages/UsersPage";

export default function Page() {
  return <UsersPage />;
}
'@

Write-SourceFile "src\app\(dashboard)\profile\page.tsx" @'
import ProfilePage from "@/features/users/pages/ProfilePage";

export default function Page() {
  return <ProfilePage />;
}
'@

# ---------- Layout dashboard SEMENTARA (diganti PostLayout di Langkah 8) ----------
Write-SourceFile "src\app\(dashboard)\layout.tsx" @'
"use client";

import { useEffect, type ReactNode } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { getAccessToken } from "@/helpers/apiHelper";
import { useAppDispatch } from "@/hooks/redux";
import { asyncLogout } from "@/features/auth/states/action";

export default function Layout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const dispatch = useAppDispatch();

  useEffect(() => {
    if (!getAccessToken()) router.replace("/auth/login");
  }, [router]);

  const logout = async () => {
    await dispatch(asyncLogout());
    router.replace("/auth/login");
  };

  return (
    <div className="min-h-screen">
      <header className="bg-indigo-950">
        <nav aria-label="Navigasi utama" className="mx-auto flex max-w-6xl items-center gap-5 px-4 py-4 text-sm font-bold text-white">
          <Link href="/" className="hover:text-amber-300">Beranda</Link>
          <Link href="/users" className="hover:text-amber-300">Pengguna</Link>
          <Link href="/profile" className="hover:text-amber-300">Profil</Link>
          <button type="button" onClick={logout} className="ml-auto text-rose-200 hover:text-rose-100">
            Keluar
          </button>
        </nav>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-8">{children}</main>
    </div>
  );
}
'@

Write-SourceFile "src\app\(dashboard)\page.tsx" @'
export default function Page() {
  return <h1 className="text-2xl font-extrabold">Dashboard (sementara)</h1>;
}
'@

# ---------- Perbaikan jarak logo di AuthLayout ----------
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
          <span>
            Post<span className="text-amber-300">Kampus</span>
          </span>
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

Write-Host ""
Write-Host "Langkah 6 selesai. Server dev otomatis memuat ulang." -ForegroundColor Cyan