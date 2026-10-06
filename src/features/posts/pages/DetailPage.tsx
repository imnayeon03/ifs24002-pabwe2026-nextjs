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
        <p>{isPost ? "Memuat postinganâ€¦" : "Postingan tidak ditemukan."}</p>
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