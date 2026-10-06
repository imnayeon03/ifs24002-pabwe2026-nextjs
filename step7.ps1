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

# ---------- Types: menambah payload postingan ----------
Write-SourceFile "src\types\action.ts" @'
export interface LoginPayload {
  email: string;
  password: string;
}

export interface RegisterPayload extends LoginPayload {
  name: string;
}

export interface ProfilePayload {
  name: string;
  email: string;
}

export interface ChangePasswordPayload {
  password: string;
  new_password: string;
  new_password_confirmation: string;
}

export interface ChangePostPayload {
  postId: number;
  description: string;
}

export interface ChangeCoverPayload {
  postId: number;
  cover: File;
}

export interface LikePayload {
  postId: number;
  like: 0 | 1;
}

export interface AddCommentPayload {
  postId: number;
  comment: string;
}
'@

# ---------- Posts: API ----------
Write-SourceFile "src\features\posts\api\postApi.ts" @'
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
'@

# ---------- Posts: thunk ----------
Write-SourceFile "src\features\posts\states\action.ts" @'
import { createAsyncThunk } from "@reduxjs/toolkit";
import { showErrorDialog, showSuccessDialog } from "@/helpers/toolsHelper";
import type {
  AddCommentPayload,
  ChangeCoverPayload,
  ChangePostPayload,
  LikePayload,
} from "@/types/action";
import type { ApiResult, Post } from "@/types";
import * as postApi from "../api/postApi";

// Menampilkan dialog sesuai hasil, mengembalikan true bila sukses
function report(result: ApiResult, announceSuccess = true): boolean {
  if (result.status !== "success") {
    void showErrorDialog(result.message);
    return false;
  }
  if (announceSuccess) void showSuccessDialog(result.message);
  return true;
}

export const asyncGetPosts = createAsyncThunk("posts/getPosts", async (isMe: boolean): Promise<Post[]> => {
  const result = await postApi.getPosts(isMe);
  if (result.status !== "success" || !result.data) {
    void showErrorDialog(result.message);
    return [];
  }
  return result.data.posts;
});

export const asyncGetPost = createAsyncThunk("posts/getPost", async (postId: number): Promise<Post | null> => {
  const result = await postApi.getPost(postId);
  if (result.status !== "success" || !result.data) {
    void showErrorDialog(result.message);
    return null;
  }
  return result.data.post;
});

export const asyncAddPost = createAsyncThunk("posts/addPost", async (description: string) =>
  report(await postApi.addPost(description)),
);

export const asyncChangePost = createAsyncThunk("posts/changePost", async (payload: ChangePostPayload) =>
  report(await postApi.changePost(payload.postId, payload.description)),
);

export const asyncChangePostCover = createAsyncThunk(
  "posts/changePostCover",
  async (payload: ChangeCoverPayload) => report(await postApi.changePostCover(payload.postId, payload.cover)),
);

export const asyncDeletePost = createAsyncThunk("posts/deletePost", async (postId: number) =>
  report(await postApi.deletePost(postId)),
);

// Like/unlike tidak menampilkan dialog sukses agar interaksi terasa ringan
export const asyncLikePost = createAsyncThunk("posts/likePost", async (payload: LikePayload) =>
  report(await postApi.likePost(payload.postId, payload.like), false),
);

export const asyncAddComment = createAsyncThunk("posts/addComment", async (payload: AddCommentPayload) =>
  report(await postApi.addComment(payload.postId, payload.comment)),
);

export const asyncDeleteComment = createAsyncThunk("posts/deleteComment", async (postId: number) =>
  report(await postApi.deleteComment(postId)),
);

export const asyncDeleteAllPosts = createAsyncThunk("posts/deleteAllPosts", async () =>
  report(await postApi.deleteAllPosts()),
);
'@

# ---------- Posts: reducer ----------
Write-SourceFile "src\features\posts\states\reducer.ts" @'
import { createSlice, type AsyncThunk } from "@reduxjs/toolkit";
import type { Post } from "@/types";
import {
  asyncAddComment,
  asyncAddPost,
  asyncChangePost,
  asyncChangePostCover,
  asyncDeleteAllPosts,
  asyncDeleteComment,
  asyncDeletePost,
  asyncGetPost,
  asyncGetPosts,
  asyncLikePost,
} from "./action";

const initialState = {
  posts: [] as Post[],
  post: null as Post | null,
  isPost: false,
  isPostAdd: false,
  isPostAdded: false,
  isPostChange: false,
  isPostChanged: false,
  isPostChangeCover: false,
  isPostChangedCover: false,
  isPostDelete: false,
  isPostDeleted: false,
  isPostLike: false,
  isPostLiked: false,
  isPostAddComment: false,
  isPostAddedComment: false,
  isPostDeleteComment: false,
  isPostDeletedComment: false,
  isPostDeleteAll: false,
  isPostDeletedAll: false,
};

type PostsState = typeof initialState;
type FlagKey = Exclude<keyof PostsState, "posts" | "post">;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type MutationThunk = AsyncThunk<boolean, any, any>;

// [thunk, penanda "sedang berjalan", penanda "sudah berhasil"]
const MUTATIONS: Array<[MutationThunk, FlagKey, FlagKey]> = [
  [asyncAddPost, "isPostAdd", "isPostAdded"],
  [asyncChangePost, "isPostChange", "isPostChanged"],
  [asyncChangePostCover, "isPostChangeCover", "isPostChangedCover"],
  [asyncDeletePost, "isPostDelete", "isPostDeleted"],
  [asyncLikePost, "isPostLike", "isPostLiked"],
  [asyncAddComment, "isPostAddComment", "isPostAddedComment"],
  [asyncDeleteComment, "isPostDeleteComment", "isPostDeletedComment"],
  [asyncDeleteAllPosts, "isPostDeleteAll", "isPostDeletedAll"],
];

const postsSlice = createSlice({
  name: "posts",
  initialState,
  reducers: {
    clearPost: (state) => {
      state.post = null;
    },
    resetPostStatus: (state) => {
      MUTATIONS.forEach(([, , done]) => {
        state[done] = false;
      });
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(asyncGetPosts.pending, (state) => {
        state.isPost = true;
      })
      .addCase(asyncGetPosts.fulfilled, (state, action) => {
        state.posts = action.payload;
        state.isPost = false;
      })
      .addCase(asyncGetPosts.rejected, (state) => {
        state.isPost = false;
      })
      .addCase(asyncGetPost.pending, (state) => {
        state.isPost = true;
      })
      .addCase(asyncGetPost.fulfilled, (state, action) => {
        state.post = action.payload;
        state.isPost = false;
      })
      .addCase(asyncGetPost.rejected, (state) => {
        state.isPost = false;
      });

    MUTATIONS.forEach(([thunk, busy, done]) => {
      builder
        .addCase(thunk.pending, (state) => {
          state[busy] = true;
          state[done] = false;
        })
        .addCase(thunk.fulfilled, (state, action) => {
          state[busy] = false;
          state[done] = action.payload;
        })
        .addCase(thunk.rejected, (state) => {
          state[busy] = false;
        });
    });
  },
});

export const { clearPost, resetPostStatus } = postsSlice.actions;
export default postsSlice.reducer;
'@

# ---------- Store: menambah slice posts ----------
Write-SourceFile "src\store.ts" @'
import { configureStore } from "@reduxjs/toolkit";
import authReducer from "@/features/auth/states/reducer";
import postsReducer from "@/features/posts/states/reducer";
import usersReducer from "@/features/users/states/reducer";

const store = configureStore({
  reducer: {
    auth: authReducer,
    users: usersReducer,
    posts: postsReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export default store;
'@

Write-Host ""
Write-Host "Langkah 7 selesai." -ForegroundColor Cyan