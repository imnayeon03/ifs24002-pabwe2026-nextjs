"use client";

import { useState, type FormEvent } from "react";
import { IconLoader2 } from "@tabler/icons-react";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import { asyncAddPost } from "../states/action";
import ModalComponent from "./ModalComponent";

interface AddModalProps {
  onClose: () => void;
  onDone: () => void;
}

export default function AddModal({ onClose, onDone }: AddModalProps) {
  const dispatch = useAppDispatch();
  const isPostAdd = useAppSelector((state) => state.posts.isPostAdd);
  const [description, setDescription] = useState("");
  const [error, setError] = useState("");

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (description.trim().length < 3) {
      setError("Deskripsi minimal 3 karakter");
      return;
    }
    setError("");
    const ok = await dispatch(asyncAddPost(description.trim())).unwrap();
    if (ok) onDone();
  };

  return (
    <ModalComponent title="Tambah postingan" titleId="judul-tambah" onClose={onClose}>
      <form onSubmit={submit} noValidate className="space-y-4">
        <div>
          <label htmlFor="add-description" className="mb-1.5 block text-sm font-bold text-stone-700">
            Deskripsi
          </label>
          <textarea
            id="add-description"
            rows={5}
            autoFocus
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full rounded-2xl border border-stone-300 bg-stone-50 px-4 py-3 outline-none focus:border-indigo-600 focus:ring-4 focus:ring-indigo-100"
          />
          {error && <p className="mt-1.5 text-sm font-medium text-rose-600">{error}</p>}
        </div>
        <button
          type="submit"
          disabled={isPostAdd}
          className="flex items-center justify-center gap-2 rounded-2xl bg-indigo-950 px-6 py-3 font-bold text-amber-300 hover:bg-indigo-900 disabled:opacity-60"
        >
          {isPostAdd && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
          Simpan postingan
        </button>
      </form>
    </ModalComponent>
  );
}