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