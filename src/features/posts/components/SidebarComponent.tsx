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