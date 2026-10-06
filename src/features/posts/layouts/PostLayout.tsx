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
          <p>Memuatâ€¦</p>
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