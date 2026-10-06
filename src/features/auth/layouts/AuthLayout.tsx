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