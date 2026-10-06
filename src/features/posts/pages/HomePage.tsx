"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { IconHeart, IconLoader2, IconMessageCircle, IconPlus, IconSearch } from "@tabler/icons-react";
import Avatar from "@/components/Avatar";
import { resolveMediaUrl } from "@/helpers/toolsHelper";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import AddModal from "../components/AddModal";
import { asyncGetPosts } from "../states/action";
import { formatDate, toPostView } from "../utils/postView";

export default function HomePage() {
  const dispatch = useAppDispatch();
  const isMine = useSearchParams().get("tampilan") === "saya";
  const { posts, isPost } = useAppSelector((state) => state.posts);
  const profile = useAppSelector((state) => state.users.profile);
  const [keyword, setKeyword] = useState("");
  const [showAdd, setShowAdd] = useState(false);

  const reload = useCallback(() => {
    void dispatch(asyncGetPosts(isMine));
  }, [dispatch, isMine]);

  useEffect(() => {
    reload();
  }, [reload]);

  const needle = keyword.trim().toLowerCase();
  const items = posts
    .map((post) => toPostView(post, profile?.id))
    .filter((post) => `${post.description} ${post.authorName}`.toLowerCase().includes(needle));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-indigo-950">
            {isMine ? "Postingan saya" : "Semua postingan"}
          </h1>
          <p className="mt-1 text-stone-600">
            {isMine ? "Cerita yang kamu bagikan." : "Lihat cerita terbaru dari seluruh pengguna."}
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowAdd(true)}
          className="flex items-center gap-2 rounded-2xl bg-indigo-950 px-5 py-3 font-bold text-amber-300 hover:bg-indigo-900"
        >
          <IconPlus size={18} aria-hidden="true" /> Tambah postingan
        </button>
      </div>

      <div className="relative">
        <IconSearch
          size={18}
          aria-hidden="true"
          className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-600"
        />
        <input
          type="search"
          aria-label="Cari postingan"
          placeholder="Cari deskripsi atau penulisâ€¦"
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
          className="w-full rounded-2xl border-0 bg-white py-3 pl-11 pr-4 outline-none ring-1 ring-stone-200 focus:ring-2 focus:ring-indigo-600"
        />
      </div>

      {isPost && (
        <p role="status" className="flex items-center justify-center gap-2 py-10 text-stone-600">
          <IconLoader2 className="animate-spin" aria-hidden="true" /> Memuat postinganâ€¦
        </p>
      )}

      {!isPost && items.length === 0 && (
        <p className="rounded-[1.75rem] border-2 border-dashed border-stone-300 py-12 text-center font-semibold text-stone-600">
          Belum ada postingan yang cocok.
        </p>
      )}

      {!isPost && items.length > 0 && (
        <ul className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {items.map((post) => {
            const cover = resolveMediaUrl(post.cover);
            return (
              <li key={post.id} className="overflow-hidden rounded-[1.75rem] bg-white ring-1 ring-stone-200">
                {cover && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={cover} alt="" className="h-44 w-full bg-stone-200 object-cover" />
                )}
                <div className="space-y-3 p-5">
                  <div className="flex items-center gap-3">
                    <Avatar name={post.authorName} photo={post.authorPhoto} size={36} />
                    <div className="min-w-0">
                      <p className="truncate text-sm font-bold text-indigo-950">{post.authorName}</p>
                      <p className="text-xs text-stone-600">{formatDate(post.createdAt)}</p>
                    </div>
                  </div>
                  <p className="line-clamp-3 text-stone-700">{post.description}</p>
                  <div className="flex items-center justify-between text-sm text-stone-600">
                    <span className="flex items-center gap-4">
                      <span className="flex items-center gap-1">
                        <IconHeart size={16} aria-hidden="true" /> {post.totalLikes}
                        <span className="sr-only"> suka</span>
                      </span>
                      <span className="flex items-center gap-1">
                        <IconMessageCircle size={16} aria-hidden="true" /> {post.totalComments}
                        <span className="sr-only"> komentar</span>
                      </span>
                    </span>
                    <Link
                      href={`/posts/${post.id}`}
                      className="font-bold text-indigo-700 hover:text-indigo-900"
                    >
                      Lihat detail
                    </Link>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {showAdd && (
        <AddModal
          onClose={() => setShowAdd(false)}
          onDone={() => {
            setShowAdd(false);
            reload();
          }}
        />
      )}
    </div>
  );
}