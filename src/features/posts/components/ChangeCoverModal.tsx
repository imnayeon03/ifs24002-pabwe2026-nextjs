"use client";

import { useState, type FormEvent } from "react";
import { IconLoader2 } from "@tabler/icons-react";
import { showWarningDialog } from "@/helpers/toolsHelper";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import { asyncChangePostCover } from "../states/action";
import ModalComponent from "./ModalComponent";

interface ChangeCoverModalProps {
  postId: number;
  onClose: () => void;
  onDone: () => void;
}

export default function ChangeCoverModal({ postId, onClose, onDone }: ChangeCoverModalProps) {
  const dispatch = useAppDispatch();
  const isPostChangeCover = useAppSelector((state) => state.posts.isPostChangeCover);
  const [cover, setCover] = useState<File | null>(null);

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!cover) {
      void showWarningDialog("Pilih gambar sampul terlebih dahulu");
      return;
    }
    const ok = await dispatch(asyncChangePostCover({ postId, cover })).unwrap();
    if (ok) onDone();
  };

  return (
    <ModalComponent title="Ubah sampul" titleId="judul-sampul" onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <div>
          <label htmlFor="change-cover" className="mb-1.5 block text-sm font-bold text-stone-700">
            Pilih gambar baru
          </label>
          <input
            id="change-cover"
            type="file"
            accept="image/*"
            onChange={(e) => setCover(e.target.files?.[0] ?? null)}
            className="w-full text-sm file:mr-3 file:rounded-lg file:border-0 file:bg-amber-100 file:px-4 file:py-2 file:font-bold file:text-amber-900"
          />
        </div>
        <button
          type="submit"
          disabled={isPostChangeCover}
          className="flex items-center justify-center gap-2 rounded-2xl bg-indigo-950 px-6 py-3 font-bold text-amber-300 hover:bg-indigo-900 disabled:opacity-60"
        >
          {isPostChangeCover && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
          Unggah sampul
        </button>
      </form>
    </ModalComponent>
  );
}