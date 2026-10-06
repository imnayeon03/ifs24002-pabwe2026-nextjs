"use client";

import { useEffect, type ReactNode } from "react";
import { IconX } from "@tabler/icons-react";

interface ModalProps {
  title: string;
  titleId: string;
  onClose: () => void;
  children: ReactNode;
}

export default function ModalComponent({ title, titleId, onClose, children }: ModalProps) {
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-50 grid place-items-center p-4">
      <div aria-hidden="true" onClick={onClose} className="absolute inset-0 bg-indigo-950/60" />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative w-full max-w-lg rounded-[2rem] bg-white p-7 shadow-2xl"
      >
        <div className="mb-5 flex items-center justify-between">
          <h2 id={titleId} className="text-xl font-extrabold text-indigo-950">
            {title}
          </h2>
          <button
            type="button"
            aria-label="Tutup"
            onClick={onClose}
            className="rounded-lg p-1.5 text-stone-600 hover:bg-stone-100"
          >
            <IconX size={22} aria-hidden="true" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}