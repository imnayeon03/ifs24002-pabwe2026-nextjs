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
          {submitting ? "Memprosesâ€¦" : "Daftar"}
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