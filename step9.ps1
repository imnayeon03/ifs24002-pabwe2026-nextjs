if (-not (Test-Path ".\package.json")) {
  Write-Host "Jalankan dari root proyek (folder yang berisi package.json)." -ForegroundColor Red
  exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-SourceFile($relativePath, $content) {
  $fullPath = Join-Path (Get-Location) $relativePath
  $dir = Split-Path $fullPath -Parent
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [System.IO.File]::WriteAllText($fullPath, $content.Replace("`r`n", "`n"), $utf8)
  Write-Host "Dibuat: $relativePath" -ForegroundColor Green
}

# ---------- Util: tampilan data postingan yang aman terhadap variasi field ----------
Write-SourceFile "src\features\posts\utils\postView.ts" @'
import type { Post } from "@/types";

interface Person {
  id?: number;
  name?: string;
  photo?: string | null;
}

interface LooseComment {
  id?: number;
  user_id?: number;
  comment?: string;
  created_at?: string;
  author?: Person;
  user?: Person;
}

interface LoosePost {
  id: number;
  user_id?: number;
  description?: string;
  cover?: string | null;
  created_at?: string;
  total_likes?: number;
  total_comments?: number;
  author?: Person;
  user?: Person;
  likes?: Array<{ user_id?: number }>;
  comments?: LooseComment[];
}

export interface CommentView {
  id: number;
  userId: number | undefined;
  text: string;
  authorName: string;
  authorPhoto: string | null | undefined;
  createdAt: string;
}

export interface PostView {
  id: number;
  description: string;
  cover: string | null | undefined;
  authorName: string;
  authorPhoto: string | null | undefined;
  createdAt: string;
  totalLikes: number;
  totalComments: number;
  isMine: boolean;
  isLiked: boolean;
  comments: CommentView[];
}

export function formatDate(value: string): string {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleDateString("id-ID", { day: "numeric", month: "long", year: "numeric" });
}

export function toPostView(post: Post, myId?: number): PostView {
  const p = post as unknown as LoosePost;
  const author = p.author ?? p.user;
  const likes = p.likes ?? [];
  const comments = p.comments ?? [];

  return {
    id: p.id,
    description: p.description ?? "",
    cover: p.cover,
    authorName: author?.name ?? "Pengguna",
    authorPhoto: author?.photo,
    createdAt: p.created_at ?? "",
    totalLikes: p.total_likes ?? likes.length,
    totalComments: p.total_comments ?? comments.length,
    isMine: myId !== undefined && (p.user_id ?? author?.id) === myId,
    isLiked: myId !== undefined && likes.some((like) => like.user_id === myId),
    comments: comments.map((c, index) => {
      const who = c.author ?? c.user;
      return {
        id: c.id ?? index,
        userId: c.user_id ?? who?.id,
        text: c.comment ?? "",
        authorName: who?.name ?? "Pengguna",
        authorPhoto: who?.photo,
        createdAt: c.created_at ?? "",
      };
    }),
  };
}
'@

# ---------- ModalComponent ----------
Write-SourceFile "src\features\posts\components\ModalComponent.tsx" @'
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
'@

# ---------- AddModal ----------
Write-SourceFile "src\features\posts\components\AddModal.tsx" @'
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
'@

# ---------- ChangeModal ----------
Write-SourceFile "src\features\posts\components\ChangeModal.tsx" @'
"use client";

import { useState, type FormEvent } from "react";
import { IconLoader2 } from "@tabler/icons-react";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import { asyncChangePost } from "../states/action";
import ModalComponent from "./ModalComponent";

interface ChangeModalProps {
  postId: number;
  initialDescription: string;
  onClose: () => void;
  onDone: () => void;
}

export default function ChangeModal({ postId, initialDescription, onClose, onDone }: ChangeModalProps) {
  const dispatch = useAppDispatch();
  const isPostChange = useAppSelector((state) => state.posts.isPostChange);
  const [description, setDescription] = useState(initialDescription);
  const [error, setError] = useState("");

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (description.trim().length < 3) {
      setError("Deskripsi minimal 3 karakter");
      return;
    }
    setError("");
    const ok = await dispatch(asyncChangePost({ postId, description: description.trim() })).unwrap();
    if (ok) onDone();
  };

  return (
    <ModalComponent title="Ubah postingan" titleId="judul-ubah" onClose={onClose}>
      <form onSubmit={submit} noValidate className="space-y-4">
        <div>
          <label htmlFor="change-description" className="mb-1.5 block text-sm font-bold text-stone-700">
            Deskripsi
          </label>
          <textarea
            id="change-description"
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
          disabled={isPostChange}
          className="flex items-center justify-center gap-2 rounded-2xl bg-indigo-950 px-6 py-3 font-bold text-amber-300 hover:bg-indigo-900 disabled:opacity-60"
        >
          {isPostChange && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
          Simpan perubahan
        </button>
      </form>
    </ModalComponent>
  );
}
'@

# ---------- ChangeCoverModal ----------
Write-SourceFile "src\features\posts\components\ChangeCoverModal.tsx" @'
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
'@

# ---------- HomePage ----------
Write-SourceFile "src\features\posts\pages\HomePage.tsx" @'
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
          placeholder="Cari deskripsi atau penulis…"
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
          className="w-full rounded-2xl border-0 bg-white py-3 pl-11 pr-4 outline-none ring-1 ring-stone-200 focus:ring-2 focus:ring-indigo-600"
        />
      </div>

      {isPost && (
        <p role="status" className="flex items-center justify-center gap-2 py-10 text-stone-600">
          <IconLoader2 className="animate-spin" aria-hidden="true" /> Memuat postingan…
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
'@

# ---------- DetailPage ----------
Write-SourceFile "src\features\posts\pages\DetailPage.tsx" @'
"use client";

import { useCallback, useEffect, useState, type FormEvent } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import {
  IconArrowLeft,
  IconHeart,
  IconHeartFilled,
  IconLoader2,
  IconPencil,
  IconPhoto,
  IconTrash,
} from "@tabler/icons-react";
import Avatar from "@/components/Avatar";
import { resolveMediaUrl } from "@/helpers/toolsHelper";
import { useAppDispatch, useAppSelector } from "@/hooks/redux";
import ChangeCoverModal from "../components/ChangeCoverModal";
import ChangeModal from "../components/ChangeModal";
import {
  asyncAddComment,
  asyncDeleteComment,
  asyncDeletePost,
  asyncGetPost,
  asyncLikePost,
} from "../states/action";
import { clearPost } from "../states/reducer";
import { formatDate, toPostView } from "../utils/postView";

export default function DetailPage() {
  const router = useRouter();
  const dispatch = useAppDispatch();
  const params = useParams<{ postId: string }>();
  const postId = Number(params.postId);

  const { post, isPost, isPostLike, isPostAddComment } = useAppSelector((state) => state.posts);
  const profile = useAppSelector((state) => state.users.profile);

  const [comment, setComment] = useState("");
  const [commentError, setCommentError] = useState("");
  const [showChange, setShowChange] = useState(false);
  const [showCover, setShowCover] = useState(false);

  const reload = useCallback(() => {
    void dispatch(asyncGetPost(postId));
  }, [dispatch, postId]);

  useEffect(() => {
    reload();
    return () => {
      dispatch(clearPost());
    };
  }, [reload, dispatch]);

  if (!post) {
    return (
      <div role="status" className="py-20 text-center text-stone-600">
        <h1 className="sr-only">Detail postingan</h1>
        <p>{isPost ? "Memuat postingan…" : "Postingan tidak ditemukan."}</p>
        <Link href="/" className="mt-4 inline-block font-bold text-indigo-700">
          Kembali ke beranda
        </Link>
      </div>
    );
  }

  const view = toPostView(post, profile?.id);
  const cover = resolveMediaUrl(view.cover);

  const toggleLike = async () => {
    const ok = await dispatch(asyncLikePost({ postId, like: view.isLiked ? 0 : 1 })).unwrap();
    if (ok) reload();
  };

  const submitComment = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (comment.trim().length === 0) {
      setCommentError("Komentar tidak boleh kosong");
      return;
    }
    setCommentError("");
    const ok = await dispatch(asyncAddComment({ postId, comment: comment.trim() })).unwrap();
    if (ok) {
      setComment("");
      reload();
    }
  };

  const removeComment = async () => {
    if (!window.confirm("Hapus komentarmu pada postingan ini?")) return;
    const ok = await dispatch(asyncDeleteComment(postId)).unwrap();
    if (ok) reload();
  };

  const removePost = async () => {
    if (!window.confirm("Hapus postingan ini? Tindakan ini tidak bisa dibatalkan.")) return;
    const ok = await dispatch(asyncDeletePost(postId)).unwrap();
    if (ok) router.replace("/");
  };

  return (
    <article className="mx-auto max-w-3xl space-y-6">
      <Link href="/" className="inline-flex items-center gap-1 text-sm font-bold text-indigo-700">
        <IconArrowLeft size={16} aria-hidden="true" /> Kembali
      </Link>

      <div className="overflow-hidden rounded-[2rem] bg-white ring-1 ring-stone-200">
        {cover && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={cover} alt="Sampul postingan" className="max-h-80 w-full bg-stone-200 object-cover" />
        )}
        <div className="space-y-4 p-7">
          <h1 className="sr-only">Detail postingan</h1>
          <div className="flex items-center gap-3">
            <Avatar name={view.authorName} photo={view.authorPhoto} size={44} />
            <div>
              <p className="font-bold text-indigo-950">{view.authorName}</p>
              <p className="text-sm text-stone-600">{formatDate(view.createdAt)}</p>
            </div>
          </div>

          <p className="whitespace-pre-line text-lg text-stone-800">{view.description}</p>

          <div className="flex flex-wrap items-center gap-3">
            <button
              type="button"
              onClick={toggleLike}
              disabled={isPostLike}
              aria-pressed={view.isLiked}
              className="flex items-center gap-2 rounded-2xl bg-rose-50 px-4 py-2 font-bold text-rose-700 hover:bg-rose-100 disabled:opacity-60"
            >
              {view.isLiked ? (
                <IconHeartFilled size={18} aria-hidden="true" />
              ) : (
                <IconHeart size={18} aria-hidden="true" />
              )}
              {view.isLiked ? "Batal suka" : "Suka"} ({view.totalLikes})
            </button>

            {view.isMine && (
              <>
                <button
                  type="button"
                  onClick={() => setShowChange(true)}
                  className="flex items-center gap-2 rounded-2xl bg-stone-100 px-4 py-2 font-bold text-stone-700 hover:bg-stone-200"
                >
                  <IconPencil size={18} aria-hidden="true" /> Ubah
                </button>
                <button
                  type="button"
                  onClick={() => setShowCover(true)}
                  className="flex items-center gap-2 rounded-2xl bg-stone-100 px-4 py-2 font-bold text-stone-700 hover:bg-stone-200"
                >
                  <IconPhoto size={18} aria-hidden="true" /> Ubah sampul
                </button>
                <button
                  type="button"
                  onClick={removePost}
                  className="flex items-center gap-2 rounded-2xl bg-rose-600 px-4 py-2 font-bold text-white hover:bg-rose-700"
                >
                  <IconTrash size={18} aria-hidden="true" /> Hapus
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      <section aria-labelledby="judul-komentar" className="rounded-[2rem] bg-white p-7 ring-1 ring-stone-200">
        <h2 id="judul-komentar" className="text-xl font-extrabold text-indigo-950">
          Komentar ({view.totalComments})
        </h2>

        <form onSubmit={submitComment} noValidate className="mt-4 space-y-3">
          <div>
            <label htmlFor="comment" className="mb-1.5 block text-sm font-bold text-stone-700">
              Tulis komentar
            </label>
            <textarea
              id="comment"
              rows={3}
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              className="w-full rounded-2xl border border-stone-300 bg-stone-50 px-4 py-3 outline-none focus:border-indigo-600 focus:ring-4 focus:ring-indigo-100"
            />
            {commentError && <p className="mt-1.5 text-sm font-medium text-rose-600">{commentError}</p>}
          </div>
          <button
            type="submit"
            disabled={isPostAddComment}
            className="flex items-center gap-2 rounded-2xl bg-indigo-950 px-5 py-2.5 font-bold text-amber-300 hover:bg-indigo-900 disabled:opacity-60"
          >
            {isPostAddComment && <IconLoader2 size={18} className="animate-spin" aria-hidden="true" />}
            Kirim komentar
          </button>
        </form>

        {view.comments.length === 0 ? (
          <p className="mt-6 text-stone-600">Belum ada komentar.</p>
        ) : (
          <ul className="mt-6 space-y-4">
            {view.comments.map((item) => (
              <li key={item.id} className="flex gap-3">
                <Avatar name={item.authorName} photo={item.authorPhoto} size={36} />
                <div className="min-w-0 flex-1 rounded-2xl bg-stone-50 px-4 py-3">
                  <div className="flex items-center justify-between gap-2">
                    <p className="truncate text-sm font-bold text-indigo-950">{item.authorName}</p>
                    {item.userId !== undefined && item.userId === profile?.id && (
                      <button
                        type="button"
                        onClick={removeComment}
                        className="text-xs font-bold text-rose-700 hover:text-rose-900"
                      >
                        Hapus
                      </button>
                    )}
                  </div>
                  <p className="mt-1 whitespace-pre-line text-stone-700">{item.text}</p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {showChange && (
        <ChangeModal
          postId={postId}
          initialDescription={view.description}
          onClose={() => setShowChange(false)}
          onDone={() => {
            setShowChange(false);
            reload();
          }}
        />
      )}
      {showCover && (
        <ChangeCoverModal
          postId={postId}
          onClose={() => setShowCover(false)}
          onDone={() => {
            setShowCover(false);
            reload();
          }}
        />
      )}
    </article>
  );
}
'@

# ---------- Rute ----------
Write-SourceFile "src\app\(dashboard)\page.tsx" @'
import { Suspense } from "react";
import HomePage from "@/features/posts/pages/HomePage";

export default function Page() {
  return (
    <Suspense fallback={null}>
      <HomePage />
    </Suspense>
  );
}
'@

Write-SourceFile "src\app\(dashboard)\posts\[postId]\page.tsx" @'
import DetailPage from "@/features/posts/pages/DetailPage";

export default function Page() {
  return <DetailPage />;
}
'@

Write-Host ""
Write-Host "Langkah 9 selesai. Server dev otomatis memuat ulang." -ForegroundColor Cyan