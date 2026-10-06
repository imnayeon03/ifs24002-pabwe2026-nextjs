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