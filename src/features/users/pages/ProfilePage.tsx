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
        <p>Memuat profilâ€¦</p>
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