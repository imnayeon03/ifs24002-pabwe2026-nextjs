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