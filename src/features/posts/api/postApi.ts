import { apiFetch } from "@/helpers/apiHelper";
import type { Post } from "@/types";

// GET /posts (is_me=1 untuk postingan milik sendiri)
export const getPosts = (isMe = false) =>
  apiFetch<{ posts: Post[] }>("/posts", { query: { is_me: isMe ? 1 : undefined } });

// GET /posts/:id
export const getPost = (postId: number) => apiFetch<{ post: Post }>(`/posts/${postId}`);

// POST /posts
export const addPost = (description: string) =>
  apiFetch<{ post_id: number }>("/posts", { method: "POST", body: { description } });

// PUT /posts/:id
export const changePost = (postId: number, description: string) =>
  apiFetch(`/posts/${postId}`, { method: "PUT", body: { description } });

// POST /posts/:id/cover (multipart)
export const changePostCover = (postId: number, cover: File) => {
  const form = new FormData();
  form.append("cover", cover);
  return apiFetch(`/posts/${postId}/cover`, { method: "POST", body: form });
};

// DELETE /posts/:id
export const deletePost = (postId: number) => apiFetch(`/posts/${postId}`, { method: "DELETE" });

// POST /posts/:id/likes  { like: 1 | 0 }
export const likePost = (postId: number, like: 0 | 1) =>
  apiFetch(`/posts/${postId}/likes`, { method: "POST", body: { like } });

// POST /posts/:id/comments  { comment }
export const addComment = (postId: number, comment: string) =>
  apiFetch(`/posts/${postId}/comments`, { method: "POST", body: { comment } });

// DELETE /posts/:id/comments (menghapus komentar milik sendiri)
export const deleteComment = (postId: number) =>
  apiFetch(`/posts/${postId}/comments`, { method: "DELETE" });

// DELETE /posts (menghapus seluruh postingan milik sendiri)
export const deleteAllPosts = () => apiFetch("/posts", { method: "DELETE" });