"use client";

import { useEffect } from "react";
import { IconLoader2, IconSearch } from "@tabler/icons-react";
import Avatar from "@/components/Avatar";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import useInput from "@/hooks/useInput";
import { asyncGetUsers } from "../states/action";

export default function UsersPage() {
  const dispatch = useAppDispatch();
  const { users, isUsers } = useAppSelector((state) => state.users);
  const keyword = useInput("");

  useEffect(() => {
    void dispatch(asyncGetUsers());
  }, [dispatch]);

  const needle = keyword.value.trim().toLowerCase();
  const visible = users.filter((user) => `${user.name} ${user.email}`.toLowerCase().includes(needle));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-indigo-950">Daftar pengguna</h1>
        <p className="mt-1 text-stone-600">Temukan pengguna yang terdaftar di aplikasi.</p>
      </div>

      <div className="relative">
        <IconSearch
          size={18}
          aria-hidden="true"
          className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-600"
        />
        <input
          type="search"
          aria-label="Cari pengguna"
          placeholder="Cari nama atau emailâ€¦"
          value={keyword.value}
          onChange={keyword.onChange}
          className="w-full rounded-2xl border-0 bg-white py-3 pl-11 pr-4 outline-none ring-1 ring-stone-200 focus:ring-2 focus:ring-indigo-600"
        />
      </div>

      {isUsers && (
        <p role="status" className="flex items-center justify-center gap-2 py-10 text-stone-600">
          <IconLoader2 className="animate-spin" aria-hidden="true" /> Memuat penggunaâ€¦
        </p>
      )}

      {!isUsers && visible.length === 0 && (
        <p className="rounded-[1.75rem] border-2 border-dashed border-stone-300 py-12 text-center font-semibold text-stone-600">
          Tidak ada pengguna yang cocok.
        </p>
      )}

      {!isUsers && visible.length > 0 && (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {visible.map((user) => (
            <li
              key={user.id}
              className="flex items-center gap-4 rounded-[1.75rem] bg-white p-5 ring-1 ring-stone-200"
            >
              <Avatar name={user.name} photo={user.photo} />
              <div className="min-w-0">
                <p className="truncate font-bold text-indigo-950">{user.name}</p>
                <p className="truncate text-sm text-stone-600">{user.email}</p>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}