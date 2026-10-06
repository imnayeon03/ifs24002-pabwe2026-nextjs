/* eslint-disable @typescript-eslint/no-explicit-any */
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, makeStore, ok, samplePost } from "@/test/utils";
import * as postApi from "../api/postApi";
import * as actions from "./action";
import { clearPost, resetPostStatus } from "./reducer";

vi.mock("../api/postApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.resetAllMocks();
});

describe("asyncGetPosts", () => {
  it("memuat daftar postingan", async () => {
    mock(postApi.getPosts).mockResolvedValue(ok({ posts: [samplePost] }));
    const store = makeStore();
    await store.dispatch(actions.asyncGetPosts(false));
    expect(store.getState().posts.posts).toHaveLength(1);
    expect(store.getState().posts.isPost).toBe(false);
  });

  it("menampilkan error dan mengosongkan daftar saat gagal", async () => {
    mock(postApi.getPosts).mockResolvedValue(fail("Gagal"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetPosts(true));
    expect(store.getState().posts.posts).toEqual([]);
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal");
  });

  it("menganggap respons sukses tanpa data sebagai gagal", async () => {
    mock(postApi.getPosts).mockResolvedValue(ok());
    const store = makeStore();
    await store.dispatch(actions.asyncGetPosts(false));
    expect(toolsHelper.showErrorDialog).toHaveBeenCalled();
  });

  it("mematikan penanda saat permintaan ditolak", async () => {
    mock(postApi.getPosts).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetPosts(false));
    expect(store.getState().posts.isPost).toBe(false);
  });
});

describe("asyncGetPost", () => {
  it("memuat satu postingan", async () => {
    mock(postApi.getPost).mockResolvedValue(ok({ post: samplePost }));
    const store = makeStore();
    await store.dispatch(actions.asyncGetPost(1));
    expect((store.getState().posts.post as any).id).toBe(1);
    expect(store.getState().posts.isPost).toBe(false);
  });

  it("mengembalikan null dan menampilkan error saat gagal", async () => {
    mock(postApi.getPost).mockResolvedValue(fail("Tidak ada"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetPost(1));
    expect(store.getState().posts.post).toBeNull();
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Tidak ada");
  });

  it("menganggap respons sukses tanpa data sebagai gagal", async () => {
    mock(postApi.getPost).mockResolvedValue(ok());
    const store = makeStore();
    await store.dispatch(actions.asyncGetPost(1));
    expect(store.getState().posts.post).toBeNull();
  });

  it("mematikan penanda saat permintaan ditolak", async () => {
    mock(postApi.getPost).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetPost(1));
    expect(store.getState().posts.isPost).toBe(false);
  });
});

interface Mutation {
  name: string;
  thunk: any;
  api: unknown;
  arg: unknown;
  busy: string;
  done: string;
  quiet?: boolean;
}

const mutations: Mutation[] = [
  { name: "asyncAddPost", thunk: actions.asyncAddPost, api: postApi.addPost, arg: "Halo", busy: "isPostAdd", done: "isPostAdded" },
  { name: "asyncChangePost", thunk: actions.asyncChangePost, api: postApi.changePost, arg: { postId: 1, description: "Baru" }, busy: "isPostChange", done: "isPostChanged" },
  { name: "asyncChangePostCover", thunk: actions.asyncChangePostCover, api: postApi.changePostCover, arg: { postId: 1, cover: new File(["x"], "a.png") }, busy: "isPostChangeCover", done: "isPostChangedCover" },
  { name: "asyncDeletePost", thunk: actions.asyncDeletePost, api: postApi.deletePost, arg: 1, busy: "isPostDelete", done: "isPostDeleted" },
  { name: "asyncLikePost", thunk: actions.asyncLikePost, api: postApi.likePost, arg: { postId: 1, like: 1 }, busy: "isPostLike", done: "isPostLiked", quiet: true },
  { name: "asyncAddComment", thunk: actions.asyncAddComment, api: postApi.addComment, arg: { postId: 1, comment: "Hai" }, busy: "isPostAddComment", done: "isPostAddedComment" },
  { name: "asyncDeleteComment", thunk: actions.asyncDeleteComment, api: postApi.deleteComment, arg: 1, busy: "isPostDeleteComment", done: "isPostDeletedComment" },
  { name: "asyncDeleteAllPosts", thunk: actions.asyncDeleteAllPosts, api: postApi.deleteAllPosts, arg: undefined, busy: "isPostDeleteAll", done: "isPostDeletedAll" },
];

describe.each(mutations)("$name", ({ thunk, api, arg, busy, done, quiet }) => {
  it("berhasil", async () => {
    mock(api).mockResolvedValue(ok());
    const store = makeStore();
    await store.dispatch(thunk(arg));
    const state = store.getState().posts as any;
    expect(state[busy]).toBe(false);
    expect(state[done]).toBe(true);
    if (quiet) {
      expect(toolsHelper.showSuccessDialog).not.toHaveBeenCalled();
    } else {
      expect(toolsHelper.showSuccessDialog).toHaveBeenCalledWith("Berhasil");
    }
  });

  it("gagal", async () => {
    mock(api).mockResolvedValue(fail("Gagal"));
    const store = makeStore();
    await store.dispatch(thunk(arg));
    const state = store.getState().posts as any;
    expect(state[done]).toBe(false);
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal");
  });

  it("ditolak", async () => {
    mock(api).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(thunk(arg));
    expect((store.getState().posts as any)[busy]).toBe(false);
  });
});

describe("reducer", () => {
  it("clearPost mengosongkan postingan terpilih", async () => {
    mock(postApi.getPost).mockResolvedValue(ok({ post: samplePost }));
    const store = makeStore();
    await store.dispatch(actions.asyncGetPost(1));
    store.dispatch(clearPost());
    expect(store.getState().posts.post).toBeNull();
  });

  it("resetPostStatus mengembalikan penanda berhasil ke false", async () => {
    mock(postApi.addPost).mockResolvedValue(ok());
    const store = makeStore();
    await store.dispatch(actions.asyncAddPost("Halo"));
    expect(store.getState().posts.isPostAdded).toBe(true);
    store.dispatch(resetPostStatus());
    expect(store.getState().posts.isPostAdded).toBe(false);
  });
});