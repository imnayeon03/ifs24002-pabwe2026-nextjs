if (-not (Test-Path ".\package.json")) {
  Write-Host "Run this from the project root (the folder that contains package.json)." -ForegroundColor Red
  exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-SourceFile($relativePath, $content) {
  $fullPath = Join-Path (Get-Location) $relativePath
  $dir = Split-Path $fullPath -Parent
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [System.IO.File]::WriteAllText($fullPath, $content.Replace("`r`n", "`n"), $utf8)
  Write-Host "Created: $relativePath" -ForegroundColor Green
}

# ---------- NavbarComponent ----------
Write-SourceFile "src\features\posts\components\NavbarComponent.tsx" @'
"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { IconChevronDown, IconLogout, IconMenu2, IconMessageCircle, IconUser } from "@tabler/icons-react";
import Avatar from "@/components/Avatar";
import type { User } from "@/types";

interface NavbarProps {
  profile: User | null;
  onOpenSidebar: () => void;
  onLogout: () => void;
}

export default function NavbarComponent({ profile, onOpenSidebar, onLogout }: NavbarProps) {
  const [menuOpen, setMenuOpen] = useState(false);
  const wrapperRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!menuOpen) return;

    const onPointerDown = (event: MouseEvent) => {
      if (!wrapperRef.current?.contains(event.target as Node)) setMenuOpen(false);
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMenuOpen(false);
    };

    document.addEventListener("mousedown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [menuOpen]);

  const name = profile?.name ?? "Pengguna";

  return (
    <header className="sticky top-0 z-20 bg-indigo-950 text-white">
      <div className="mx-auto flex max-w-7xl items-center gap-3 px-4 py-3">
        <button
          type="button"
          aria-label="Buka menu navigasi"
          onClick={onOpenSidebar}
          className="rounded-lg p-1.5 hover:bg-indigo-900 lg:hidden"
        >
          <IconMenu2 size={24} aria-hidden="true" />
        </button>

        <Link href="/" className="flex items-center gap-2 text-xl font-extrabold">
          <span className="grid size-9 place-items-center rounded-xl bg-amber-300 text-indigo-950">
            <IconMessageCircle size={20} aria-hidden="true" />
          </span>
          <span>
            Post<span className="text-amber-300">Kampus</span>
          </span>
        </Link>

        <div ref={wrapperRef} className="relative ml-auto">
          <button
            type="button"
            aria-expanded={menuOpen}
            aria-controls="menu-akun"
            aria-label="Menu akun"
            onClick={() => setMenuOpen((value) => !value)}
            className="flex items-center gap-2 rounded-full py-1 pl-1 pr-3 hover:bg-indigo-900"
          >
            <Avatar name={name} photo={profile?.photo} size={36} />
            <span className="hidden max-w-40 truncate text-sm font-bold sm:block">{name}</span>
            <IconChevronDown size={16} aria-hidden="true" />
          </button>

          {menuOpen && (
            <div
              id="menu-akun"
              className="absolute right-0 mt-2 w-60 rounded-2xl bg-white p-2 text-stone-800 shadow-xl ring-1 ring-stone-200"
            >
              <div className="border-b border-stone-200 px-3 pb-2 pt-1">
                <p className="truncate text-sm font-bold text-indigo-950">{name}</p>
                <p className="truncate text-xs text-stone-600">{profile?.email}</p>
              </div>
              <Link
                href="/profile"
                onClick={() => setMenuOpen(false)}
                className="mt-1 flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold hover:bg-stone-100"
              >
                <IconUser size={18} aria-hidden="true" /> Profil saya
              </Link>
              <button
                type="button"
                onClick={onLogout}
                className="flex w-full items-center gap-2 rounded-xl px-3 py-2 text-left text-sm font-semibold text-rose-700 hover:bg-rose-50"
              >
                <IconLogout size={18} aria-hidden="true" /> Keluar
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
'@

# ---------- SidebarComponent ----------
Write-SourceFile "src\features\posts\components\SidebarComponent.tsx" @'
"use client";

import { useEffect } from "react";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { IconArticle, IconUser, IconUsers, IconUserCircle, IconX } from "@tabler/icons-react";

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

const ITEMS = [
  { id: "semua", href: "/", label: "Semua Postingan", Icon: IconArticle },
  { id: "saya", href: "/?tampilan=saya", label: "Postingan Saya", Icon: IconUserCircle },
  { id: "pengguna", href: "/users", label: "Daftar Pengguna", Icon: IconUsers },
  { id: "profil", href: "/profile", label: "Profil Saya", Icon: IconUser },
] as const;

export default function SidebarComponent({ open, onClose }: SidebarProps) {
  const pathname = usePathname();
  const showingMine = useSearchParams().get("tampilan") === "saya";

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  const isActive = (id: string) => {
    if (id === "semua") return pathname === "/" && !showingMine;
    if (id === "saya") return pathname === "/" && showingMine;
    if (id === "pengguna") return pathname.startsWith("/users");
    return pathname.startsWith("/profile");
  };

  return (
    <>
      {open && (
        <div
          aria-hidden="true"
          onClick={onClose}
          className="fixed inset-0 z-30 bg-indigo-950/50 lg:hidden"
        />
      )}

      <aside
        aria-label="Menu samping"
        className={`fixed inset-y-0 left-0 z-40 w-64 transform bg-white p-5 shadow-xl transition-transform lg:static lg:z-auto lg:translate-x-0 lg:bg-transparent lg:p-4 lg:shadow-none ${
          open ? "visible translate-x-0" : "invisible -translate-x-full lg:visible"
        }`}
      >
        <div className="mb-4 flex items-center justify-between lg:hidden">
          <p className="text-lg font-extrabold text-indigo-950">Menu</p>
          <button
            type="button"
            aria-label="Tutup menu navigasi"
            onClick={onClose}
            className="rounded-lg p-1.5 text-stone-600 hover:bg-stone-100"
          >
            <IconX size={22} aria-hidden="true" />
          </button>
        </div>

        <nav aria-label="Navigasi utama">
          <ul className="space-y-1">
            {ITEMS.map(({ id, href, label, Icon }) => {
              const active = isActive(id);
              return (
                <li key={id}>
                  <Link
                    href={href}
                    onClick={onClose}
                    aria-current={active ? "page" : undefined}
                    className={`flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-bold transition ${
                      active
                        ? "bg-indigo-950 text-amber-300"
                        : "text-stone-700 hover:bg-stone-200/70"
                    }`}
                  >
                    <Icon size={20} aria-hidden="true" /> {label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>
    </>
  );
}
'@

# ---------- PostLayout ----------
Write-SourceFile "src\features\posts\layouts\PostLayout.tsx" @'
"use client";

import { Suspense, useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { asyncLogout } from "@/features/auth/states/action";
import { asyncGetProfile } from "@/features/users/states/action";
import { getAccessToken, removeAccessToken } from "@/helpers/apiHelper";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import NavbarComponent from "../components/NavbarComponent";
import SidebarComponent from "../components/SidebarComponent";

export default function PostLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const dispatch = useAppDispatch();
  const profile = useAppSelector((state) => state.users.profile);
  const [ready, setReady] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  // Route guard: verifikasi token dan muat profil sebelum menampilkan halaman
  useEffect(() => {
    let active = true;

    const verify = async () => {
      if (!getAccessToken()) {
        router.replace("/auth/login");
        return;
      }
      const user = await dispatch(asyncGetProfile()).unwrap();
      if (!active) return;
      if (!user) {
        removeAccessToken();
        router.replace("/auth/login");
        return;
      }
      setReady(true);
    };

    void verify();
    return () => {
      active = false;
    };
  }, [dispatch, router]);

  const logout = async () => {
    await dispatch(asyncLogout());
    router.replace("/auth/login");
  };

  if (!ready) {
    return (
      <main className="grid min-h-screen place-items-center">
        <div role="status" className="text-center text-stone-600">
          <h1 className="sr-only">PostKampus</h1>
          <p>Memuat…</p>
        </div>
      </main>
    );
  }

  return (
    <div className="min-h-screen bg-stone-100">
      <a
        href="#konten-utama"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-white focus:px-4 focus:py-2"
      >
        Lewati ke konten utama
      </a>

      <NavbarComponent profile={profile} onOpenSidebar={() => setSidebarOpen(true)} onLogout={logout} />

      <div className="mx-auto flex max-w-7xl">
        <Suspense fallback={null}>
          <SidebarComponent open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        </Suspense>
        <main id="konten-utama" className="min-w-0 flex-1 px-4 py-8">
          {children}
        </main>
      </div>
    </div>
  );
}
'@

# ---------- Rute: layout dashboard memakai PostLayout ----------
Write-SourceFile "src\app\(dashboard)\layout.tsx" @'
import type { ReactNode } from "react";
import PostLayout from "@/features/posts/layouts/PostLayout";

export default function Layout({ children }: { children: ReactNode }) {
  return <PostLayout>{children}</PostLayout>;
}
'@

Write-Host ""
Write-Host "Step 8 done. The dev server reloads automatically." -ForegroundColor Cyan