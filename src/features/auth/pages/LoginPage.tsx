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
          {submitting ? "Memprosesâ€¦" : "Masuk"}
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