import { combineReducers, configureStore } from "@reduxjs/toolkit";
import { render } from "@testing-library/react";
import type { ReactElement } from "react";
import { Provider } from "react-redux";
import authReducer from "@/features/auth/states/reducer";
import postsReducer from "@/features/posts/states/reducer";
import usersReducer from "@/features/users/states/reducer";

export const initialPosts = postsReducer(undefined, { type: "test/init" });
export const initialUsers = usersReducer(undefined, { type: "test/init" });

export const me = { id: 7, name: "Budi", email: "budi@mail.id", photo: null };

export const samplePost = {
  id: 1,
  user_id: 7,
  description: "Halo kampus",
  cover: "c.png",
  created_at: "2026-01-05T00:00:00Z",
  total_likes: 2,
  total_comments: 1,
  author: { id: 7, name: "Budi", photo: null },
  likes: [{ user_id: 7 }, { user_id: 8 }],
  comments: [
    {
      id: 5,
      user_id: 7,
      comment: "Mantap",
      created_at: "2026-01-06T00:00:00Z",
      author: { id: 7, name: "Budi", photo: null },
    },
  ],
};

export function ok(data?: unknown) {
  return { status: "success", message: "Berhasil", data } as never;
}

export function fail(message = "Gagal") {
  return { status: "fail", message } as never;
}

export function withProfile(id = 7) {
  return { users: { ...initialUsers, profile: { ...me, id } } };
}

const rootReducer = combineReducers({ auth: authReducer, users: usersReducer, posts: postsReducer });

type TestState = ReturnType<typeof rootReducer>;

export function makeStore(preloaded: Record<string, unknown> = {}) {
  return configureStore({
    reducer: rootReducer,
    preloadedState: preloaded as Partial<TestState>,
  });
}

export function renderWithStore(ui: ReactElement, preloaded: Record<string, unknown> = withProfile()) {
  const store = makeStore(preloaded);
  return { store, ...render(<Provider store={store}>{ui}</Provider>) };
}