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