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

# ---------- Instal dependensi uji ----------
Write-Host "Memasang Vitest dan Testing Library..." -ForegroundColor Cyan
npm.cmd install -D "@vitejs/plugin-react@^4" jsdom "@testing-library/dom" "@testing-library/react" "@testing-library/jest-dom" "@testing-library/user-event" "@vitest/coverage-v8@1.6.1"
if ($LASTEXITCODE -ne 0) {
  Write-Host "Instalasi gagal. Periksa pesan error di atas." -ForegroundColor Red
  exit 1
}

npm.cmd pkg set scripts.test="vitest run"
npm.cmd pkg set scripts.coverage="vitest run --coverage"

# ---------- Konfigurasi ----------
Write-SourceFile "vitest.config.ts" @'
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/*.test.{ts,tsx}"],
    coverage: {
      provider: "v8",
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/app/**", "src/types/**", "src/test/**", "src/**/*.test.{ts,tsx}", "src/**/*.d.ts"],
      reporter: ["text", "html"],
      thresholds: { statements: 100, branches: 100, functions: 100, lines: 100 },
    },
  },
});
'@

Write-SourceFile "src\test\setup.ts" @'
import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach, vi } from "vitest";

// next/link tidak butuh router saat diuji: cukup render sebagai <a>
vi.mock("next/link", async () => {
  const React = await import("react");
  return {
    default: ({ href, children, ...rest }: Record<string, unknown>) =>
      React.createElement("a", { ...rest, href }, children as never),
  };
});

afterEach(() => {
  cleanup();
});
'@

Write-SourceFile "src\test\utils.tsx" @'
import { configureStore } from "@reduxjs/toolkit";
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

export function makeStore(preloaded: Record<string, unknown> = {}) {
  return configureStore({
    reducer: { auth: authReducer, users: usersReducer, posts: postsReducer },
    preloadedState: preloaded as never,
  });
}

export function renderWithStore(ui: ReactElement, preloaded: Record<string, unknown> = withProfile()) {
  const store = makeStore(preloaded);
  return { store, ...render(<Provider store={store}>{ui}</Provider>) };
}
'@

# ---------- Tes: util postView ----------
Write-SourceFile "src\features\posts\utils\postView.test.ts" @'
import { describe, expect, it } from "vitest";
import type { Post } from "@/types";
import { formatDate, toPostView } from "./postView";

const asPost = (value: unknown) => value as Post;

describe("formatDate", () => {
  it("mengembalikan string kosong untuk nilai kosong atau tidak valid", () => {
    expect(formatDate("")).toBe("");
    expect(formatDate("bukan-tanggal")).toBe("");
  });

  it("memformat tanggal valid", () => {
    expect(formatDate("2026-01-05T00:00:00Z")).toContain("2026");
  });
});

describe("toPostView", () => {
  it("memetakan postingan lengkap milik sendiri", () => {
    const view = toPostView(
      asPost({
        id: 1,
        user_id: 7,
        description: "Halo",
        cover: "c.png",
        created_at: "2026-01-05",
        total_likes: 3,
        total_comments: 2,
        author: { id: 7, name: "Budi", photo: "b.png" },
        likes: [{ user_id: 7 }],
        comments: [
          {
            id: 5,
            user_id: 7,
            comment: "Mantap",
            created_at: "2026-01-06",
            author: { id: 7, name: "Budi", photo: "b.png" },
          },
        ],
      }),
      7,
    );
    expect(view).toMatchObject({
      id: 1,
      description: "Halo",
      authorName: "Budi",
      totalLikes: 3,
      totalComments: 2,
      isMine: true,
      isLiked: true,
    });
    expect(view.comments[0]).toMatchObject({ id: 5, userId: 7, text: "Mantap", authorName: "Budi" });
  });

  it("memakai nilai bawaan untuk data minimal", () => {
    const view = toPostView(asPost({ id: 2 }));
    expect(view).toMatchObject({
      description: "",
      authorName: "Pengguna",
      createdAt: "",
      totalLikes: 0,
      totalComments: 0,
      isMine: false,
      isLiked: false,
      comments: [],
    });
  });

  it("mengenali pemilik lewat author.id dan komentar dengan field alternatif", () => {
    const view = toPostView(
      asPost({
        id: 3,
        author: { id: 9 },
        comments: [{ user: { id: 9, name: "Sari" } }, {}],
      }),
      9,
    );
    expect(view.isMine).toBe(true);
    expect(view.isLiked).toBe(false);
    expect(view.comments[0]).toMatchObject({ id: 0, userId: 9, text: "", authorName: "Sari", createdAt: "" });
    expect(view.comments[1]).toMatchObject({ id: 1, userId: undefined, authorName: "Pengguna" });
  });

  it("memakai field user bila author tidak ada dan membedakan pemilik lain", () => {
    const view = toPostView(asPost({ id: 4, user_id: 1, user: { name: "Ani" } }), 2);
    expect(view.authorName).toBe("Ani");
    expect(view.isMine).toBe(false);
  });
});
'@

# ---------- Tes: state posts ----------
Write-SourceFile "src\features\posts\states\posts.test.ts" @'
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
'@

# ---------- Tes: state users ----------
Write-SourceFile "src\features\users\states\users.test.ts" @'
/* eslint-disable @typescript-eslint/no-explicit-any */
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, makeStore, me, ok } from "@/test/utils";
import * as userApi from "../api/userApi";
import * as actions from "./action";

vi.mock("../api/userApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.resetAllMocks();
  mock(userApi.getProfile).mockResolvedValue(ok({ user: me }));
});

describe("asyncGetUsers", () => {
  it("memuat daftar pengguna", async () => {
    mock(userApi.getUsers).mockResolvedValue(ok({ users: [me] }));
    const store = makeStore();
    await store.dispatch(actions.asyncGetUsers());
    expect(store.getState().users.users).toHaveLength(1);
    expect(store.getState().users.isUsers).toBe(false);
  });

  it("menampilkan error saat gagal atau tanpa data", async () => {
    mock(userApi.getUsers).mockResolvedValue(fail("Gagal"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetUsers());
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal");

    mock(userApi.getUsers).mockResolvedValue(ok());
    await store.dispatch(actions.asyncGetUsers());
    expect(store.getState().users.users).toEqual([]);
  });

  it("mematikan penanda saat ditolak", async () => {
    mock(userApi.getUsers).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetUsers());
    expect(store.getState().users.isUsers).toBe(false);
  });
});

describe("asyncGetProfile", () => {
  it("memuat profil", async () => {
    const store = makeStore();
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.profile).toEqual(me);
    expect(store.getState().users.isProfile).toBe(false);
  });

  it("tidak menimpa profil lama saat gagal atau tanpa data", async () => {
    const store = makeStore();
    await store.dispatch(actions.asyncGetProfile());

    mock(userApi.getProfile).mockResolvedValue(fail("Token salah"));
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.profile).toEqual(me);

    mock(userApi.getProfile).mockResolvedValue(ok());
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.profile).toEqual(me);
  });

  it("mematikan penanda saat ditolak", async () => {
    mock(userApi.getProfile).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.isProfile).toBe(false);
  });
});

interface Mutation {
  name: string;
  thunk: any;
  api: unknown;
  arg: unknown;
  flag: string;
}

const mutations: Mutation[] = [
  { name: "asyncChangeProfile", thunk: actions.asyncChangeProfile, api: userApi.changeProfile, arg: { name: "Budi", email: "budi@mail.id" }, flag: "isChangeProfile" },
  { name: "asyncChangeProfilePhoto", thunk: actions.asyncChangeProfilePhoto, api: userApi.changeProfilePhoto, arg: new File(["x"], "a.png"), flag: "isChangeProfilePhoto" },
  { name: "asyncChangeProfilePassword", thunk: actions.asyncChangeProfilePassword, api: userApi.changePassword, arg: { password: "lama123", new_password: "baru123", new_password_confirmation: "baru123" }, flag: "isChangeProfilePassword" },
];

describe.each(mutations)("$name", ({ thunk, api, arg, flag }) => {
  it("berhasil", async () => {
    mock(api).mockResolvedValue(ok());
    const store = makeStore();
    await store.dispatch(thunk(arg));
    expect((store.getState().users as any)[flag]).toBe(false);
    expect(toolsHelper.showSuccessDialog).toHaveBeenCalledWith("Berhasil");
  });

  it("gagal", async () => {
    mock(api).mockResolvedValue(fail("Gagal"));
    const store = makeStore();
    await store.dispatch(thunk(arg));
    expect((store.getState().users as any)[flag]).toBe(false);
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal");
  });

  it("ditolak", async () => {
    mock(api).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(thunk(arg));
    expect((store.getState().users as any)[flag]).toBe(false);
  });
});
'@

# ---------- Tes: Avatar ----------
Write-SourceFile "src\components\Avatar.test.tsx" @'
import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Avatar from "./Avatar";

vi.mock("@/helpers/toolsHelper", () => ({
  resolveMediaUrl: (photo?: string | null) => (photo ? `http://cdn/${photo}` : null),
}));

describe("Avatar", () => {
  it("menampilkan foto bila ada", () => {
    render(<Avatar name="Budi" photo="b.png" size={50} />);
    const img = screen.getByAltText("Foto Budi");
    expect(img).toHaveAttribute("src", "http://cdn/b.png");
    expect(img).toHaveAttribute("width", "50");
  });

  it("menampilkan inisial huruf besar bila tanpa foto", () => {
    render(<Avatar name="  budi" />);
    expect(screen.getByText("B")).toBeInTheDocument();
  });

  it("menampilkan tanda tanya bila nama kosong", () => {
    render(<Avatar name="" photo={null} />);
    expect(screen.getByText("?")).toBeInTheDocument();
  });
});
'@

# ---------- Tes: modal ----------
Write-SourceFile "src\features\posts\components\modals.test.tsx" @'
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, ok, renderWithStore } from "@/test/utils";
import * as postApi from "../api/postApi";
import AddModal from "./AddModal";
import ChangeCoverModal from "./ChangeCoverModal";
import ChangeModal from "./ChangeModal";

vi.mock("../api/postApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
  showWarningDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.resetAllMocks();
});

describe("AddModal", () => {
  const setup = () => {
    const onClose = vi.fn();
    const onDone = vi.fn();
    renderWithStore(<AddModal onClose={onClose} onDone={onDone} />);
    return { onClose, onDone, user: userEvent.setup() };
  };

  it("menolak deskripsi yang terlalu pendek", async () => {
    const { user } = setup();
    await user.click(screen.getByRole("button", { name: "Simpan postingan" }));
    expect(screen.getByText("Deskripsi minimal 3 karakter")).toBeInTheDocument();
    expect(postApi.addPost).not.toHaveBeenCalled();
  });

  it("menyimpan postingan lalu memanggil onDone", async () => {
    mock(postApi.addPost).mockResolvedValue(ok());
    const { user, onDone } = setup();
    await user.type(screen.getByLabelText("Deskripsi"), "Halo dunia");
    await user.click(screen.getByRole("button", { name: "Simpan postingan" }));
    await waitFor(() => expect(onDone).toHaveBeenCalled());
    expect(postApi.addPost).toHaveBeenCalledWith("Halo dunia");
  });

  it("tidak memanggil onDone saat gagal", async () => {
    mock(postApi.addPost).mockResolvedValue(fail("Gagal"));
    const { user, onDone } = setup();
    await user.type(screen.getByLabelText("Deskripsi"), "Halo dunia");
    await user.click(screen.getByRole("button", { name: "Simpan postingan" }));
    await waitFor(() => expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal"));
    expect(onDone).not.toHaveBeenCalled();
  });

  it("bisa ditutup lewat Escape, tombol tutup, dan latar", async () => {
    const { user, onClose } = setup();
    await user.keyboard("{Escape}");
    expect(onClose).toHaveBeenCalledTimes(1);
    await user.click(screen.getByRole("button", { name: "Tutup" }));
    expect(onClose).toHaveBeenCalledTimes(2);
    await user.click(document.querySelector("div[aria-hidden='true']") as Element);
    expect(onClose).toHaveBeenCalledTimes(3);
  });
});

describe("ChangeModal", () => {
  const setup = () => {
    const onClose = vi.fn();
    const onDone = vi.fn();
    renderWithStore(
      <ChangeModal postId={1} initialDescription="Lama" onClose={onClose} onDone={onDone} />,
    );
    return { onClose, onDone, user: userEvent.setup() };
  };

  it("menampilkan deskripsi lama dan menolak yang terlalu pendek", async () => {
    const { user } = setup();
    const field = screen.getByLabelText("Deskripsi");
    expect(field).toHaveValue("Lama");
    await user.clear(field);
    await user.type(field, "ab");
    await user.click(screen.getByRole("button", { name: "Simpan perubahan" }));
    expect(screen.getByText("Deskripsi minimal 3 karakter")).toBeInTheDocument();
    expect(postApi.changePost).not.toHaveBeenCalled();
  });

  it("menyimpan perubahan lalu memanggil onDone", async () => {
    mock(postApi.changePost).mockResolvedValue(ok());
    const { user, onDone } = setup();
    const field = screen.getByLabelText("Deskripsi");
    await user.clear(field);
    await user.type(field, "Baru sekali");
    await user.click(screen.getByRole("button", { name: "Simpan perubahan" }));
    await waitFor(() => expect(onDone).toHaveBeenCalled());
    expect(postApi.changePost).toHaveBeenCalledWith(1, "Baru sekali");
  });

  it("tidak memanggil onDone saat gagal", async () => {
    mock(postApi.changePost).mockResolvedValue(fail("Gagal"));
    const { user, onDone } = setup();
    await user.click(screen.getByRole("button", { name: "Simpan perubahan" }));
    await waitFor(() => expect(toolsHelper.showErrorDialog).toHaveBeenCalled());
    expect(onDone).not.toHaveBeenCalled();
  });
});

describe("ChangeCoverModal", () => {
  const setup = () => {
    const onClose = vi.fn();
    const onDone = vi.fn();
    renderWithStore(<ChangeCoverModal postId={1} onClose={onClose} onDone={onDone} />);
    return { onClose, onDone, user: userEvent.setup() };
  };
  const file = () => new File(["x"], "a.png", { type: "image/png" });

  it("memperingatkan bila belum memilih gambar", async () => {
    const { user } = setup();
    await user.click(screen.getByRole("button", { name: "Unggah sampul" }));
    expect(toolsHelper.showWarningDialog).toHaveBeenCalledWith("Pilih gambar sampul terlebih dahulu");
    expect(postApi.changePostCover).not.toHaveBeenCalled();
  });

  it("mengunggah sampul lalu memanggil onDone", async () => {
    mock(postApi.changePostCover).mockResolvedValue(ok());
    const { user, onDone } = setup();
    const chosen = file();
    await user.upload(screen.getByLabelText("Pilih gambar baru"), chosen);
    await user.click(screen.getByRole("button", { name: "Unggah sampul" }));
    await waitFor(() => expect(onDone).toHaveBeenCalled());
    expect(postApi.changePostCover).toHaveBeenCalledWith(1, chosen);
  });

  it("tidak memanggil onDone saat gagal", async () => {
    mock(postApi.changePostCover).mockResolvedValue(fail("Gagal"));
    const { user, onDone } = setup();
    await user.upload(screen.getByLabelText("Pilih gambar baru"), file());
    await user.click(screen.getByRole("button", { name: "Unggah sampul" }));
    await waitFor(() => expect(toolsHelper.showErrorDialog).toHaveBeenCalled());
    expect(onDone).not.toHaveBeenCalled();
  });
});
'@

# ---------- Tes: Navbar dan Sidebar ----------
Write-SourceFile "src\features\posts\components\layout.test.tsx" @'
import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { me } from "@/test/utils";
import NavbarComponent from "./NavbarComponent";
import SidebarComponent from "./SidebarComponent";

const nav = vi.hoisted(() => ({ pathname: "/", query: "" }));
vi.mock("next/navigation", () => ({
  usePathname: () => nav.pathname,
  useSearchParams: () => new URLSearchParams(nav.query),
}));

beforeEach(() => {
  nav.pathname = "/";
  nav.query = "";
});

describe("NavbarComponent", () => {
  const setup = (profile: unknown = me) => {
    const onOpenSidebar = vi.fn();
    const onLogout = vi.fn();
    render(
      <NavbarComponent profile={profile as never} onOpenSidebar={onOpenSidebar} onLogout={onLogout} />,
    );
    return { onOpenSidebar, onLogout, user: userEvent.setup() };
  };
  const toggle = () => screen.getByRole("button", { name: "Menu akun" });

  it("membuka dan menutup menu akun", async () => {
    const { user } = setup();
    expect(toggle()).toHaveAttribute("aria-expanded", "false");
    await user.click(toggle());
    expect(toggle()).toHaveAttribute("aria-expanded", "true");
    expect(screen.getByText("budi@mail.id")).toBeInTheDocument();
    await user.click(toggle());
    expect(screen.queryByText("budi@mail.id")).not.toBeInTheDocument();
  });

  it("menutup menu lewat Escape, tetapi tidak lewat tombol lain", async () => {
    const { user } = setup();
    await user.click(toggle());
    fireEvent.keyDown(document, { key: "a" });
    expect(screen.getByText("budi@mail.id")).toBeInTheDocument();
    fireEvent.keyDown(document, { key: "Escape" });
    expect(screen.queryByText("budi@mail.id")).not.toBeInTheDocument();
  });

  it("menutup menu saat klik di luar, bukan saat klik di dalam", async () => {
    const { user } = setup();
    await user.click(toggle());
    fireEvent.mouseDown(screen.getByText("budi@mail.id"));
    expect(screen.getByText("budi@mail.id")).toBeInTheDocument();
    fireEvent.mouseDown(document.body);
    expect(screen.queryByText("budi@mail.id")).not.toBeInTheDocument();
  });

  it("menutup menu setelah memilih Profil saya", async () => {
    const { user } = setup();
    await user.click(toggle());
    await user.click(screen.getByRole("link", { name: "Profil saya" }));
    expect(screen.queryByText("budi@mail.id")).not.toBeInTheDocument();
  });

  it("memanggil onLogout dan onOpenSidebar", async () => {
    const { user, onLogout, onOpenSidebar } = setup();
    await user.click(screen.getByRole("button", { name: "Buka menu navigasi" }));
    expect(onOpenSidebar).toHaveBeenCalled();
    await user.click(toggle());
    await user.click(screen.getByRole("button", { name: "Keluar" }));
    expect(onLogout).toHaveBeenCalled();
  });

  it("memakai nama bawaan saat profil belum ada", () => {
    setup(null);
    expect(screen.getByText("Pengguna")).toBeInTheDocument();
  });
});

describe("SidebarComponent", () => {
  const setup = (open = false) => {
    const onClose = vi.fn();
    const view = render(<SidebarComponent open={open} onClose={onClose} />);
    return { onClose, user: userEvent.setup(), ...view };
  };

  it.each([
    ["/", "", "Semua Postingan"],
    ["/", "tampilan=saya", "Postingan Saya"],
    ["/users", "", "Daftar Pengguna"],
    ["/profile", "", "Profil Saya"],
  ])("menandai menu aktif untuk %s?%s", (pathname, query, label) => {
    nav.pathname = pathname;
    nav.query = query;
    setup();
    expect(screen.getByRole("link", { name: label })).toHaveAttribute("aria-current", "page");
    expect(screen.getAllByRole("link").filter((l) => l.hasAttribute("aria-current"))).toHaveLength(1);
  });

  it("tidak menampilkan latar saat tertutup dan mengabaikan Escape", () => {
    const { onClose, container } = setup(false);
    expect(container.querySelector("div[aria-hidden='true']")).toBeNull();
    fireEvent.keyDown(document, { key: "Escape" });
    expect(onClose).not.toHaveBeenCalled();
  });

  it("menutup drawer lewat latar, Escape, tombol tutup, dan tautan", async () => {
    const { onClose, user, container } = setup(true);
    await user.click(container.querySelector("div[aria-hidden='true']") as Element);
    expect(onClose).toHaveBeenCalledTimes(1);
    fireEvent.keyDown(document, { key: "a" });
    expect(onClose).toHaveBeenCalledTimes(1);
    fireEvent.keyDown(document, { key: "Escape" });
    expect(onClose).toHaveBeenCalledTimes(2);
    await user.click(screen.getByRole("button", { name: "Tutup menu navigasi" }));
    expect(onClose).toHaveBeenCalledTimes(3);
    await user.click(screen.getByRole("link", { name: "Daftar Pengguna" }));
    expect(onClose).toHaveBeenCalledTimes(4);
  });
});
'@

# ---------- Tes: HomePage ----------
Write-SourceFile "src\features\posts\pages\HomePage.test.tsx" @'
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ok, renderWithStore, samplePost } from "@/test/utils";
import * as postApi from "../api/postApi";
import HomePage from "./HomePage";

const nav = vi.hoisted(() => ({ query: "" }));
vi.mock("next/navigation", () => ({
  useSearchParams: () => new URLSearchParams(nav.query),
}));
vi.mock("../api/postApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
  resolveMediaUrl: (photo?: string | null) => (photo ? `http://cdn/${photo}` : null),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;
const noCover = { ...samplePost, id: 2, cover: null, description: "Tanpa sampul" };

beforeEach(() => {
  vi.resetAllMocks();
  nav.query = "";
  mock(postApi.getPosts).mockResolvedValue(ok({ posts: [samplePost, noCover] }));
});

describe("HomePage", () => {
  it("menampilkan semua postingan", async () => {
    const { container } = renderWithStore(<HomePage />);
    expect(await screen.findByText("Halo kampus")).toBeInTheDocument();
    expect(screen.getByText("Tanpa sampul")).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Semua postingan" })).toBeInTheDocument();
    expect(postApi.getPosts).toHaveBeenCalledWith(false);
    expect(container.querySelector("img[src='http://cdn/c.png']")).not.toBeNull();
    expect(screen.getAllByRole("link", { name: "Lihat detail" })[0]).toHaveAttribute("href", "/posts/1");
  });

  it("menampilkan postingan milik sendiri bila tampilan=saya", async () => {
    nav.query = "tampilan=saya";
    renderWithStore(<HomePage />);
    expect(await screen.findByRole("heading", { name: "Postingan saya" })).toBeInTheDocument();
    expect(postApi.getPosts).toHaveBeenCalledWith(true);
  });

  it("menampilkan status memuat", async () => {
    mock(postApi.getPosts).mockReturnValue(new Promise(() => {}));
    renderWithStore(<HomePage />);
    expect(await screen.findByText(/Memuat postingan/)).toBeInTheDocument();
  });

  it("menyaring postingan lewat pencarian", async () => {
    const user = userEvent.setup();
    renderWithStore(<HomePage />);
    await screen.findByText("Halo kampus");
    const search = screen.getByRole("searchbox", { name: "Cari postingan" });

    await user.type(search, "Tanpa");
    expect(screen.queryByText("Halo kampus")).not.toBeInTheDocument();
    expect(screen.getByText("Tanpa sampul")).toBeInTheDocument();

    await user.clear(search);
    await user.type(search, "zzz");
    expect(screen.getByText("Belum ada postingan yang cocok.")).toBeInTheDocument();
  });

  it("menambah postingan lewat modal lalu memuat ulang daftar", async () => {
    mock(postApi.addPost).mockResolvedValue(ok());
    const user = userEvent.setup();
    renderWithStore(<HomePage />);
    await screen.findByText("Halo kampus");

    await user.click(screen.getByRole("button", { name: "Tambah postingan" }));
    await user.type(screen.getByLabelText("Deskripsi"), "Cerita baru");
    await user.click(screen.getByRole("button", { name: "Simpan postingan" }));

    await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument());
    expect(postApi.addPost).toHaveBeenCalledWith("Cerita baru");
    expect(postApi.getPosts).toHaveBeenCalledTimes(2);
  });

  it("menutup modal tambah tanpa menyimpan", async () => {
    const user = userEvent.setup();
    renderWithStore(<HomePage />);
    await screen.findByText("Halo kampus");
    await user.click(screen.getByRole("button", { name: "Tambah postingan" }));
    await user.click(screen.getByRole("button", { name: "Tutup" }));
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  });
});
'@

# ---------- Tes: DetailPage ----------
Write-SourceFile "src\features\posts\pages\DetailPage.test.tsx" @'
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { fail, ok, renderWithStore, samplePost, withProfile } from "@/test/utils";
import * as postApi from "../api/postApi";
import DetailPage from "./DetailPage";

const nav = vi.hoisted(() => ({ replace: vi.fn() }));
vi.mock("next/navigation", () => ({
  useParams: () => ({ postId: "1" }),
  useRouter: () => ({ replace: nav.replace }),
}));
vi.mock("../api/postApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
  showWarningDialog: vi.fn(),
  resolveMediaUrl: (photo?: string | null) => (photo ? `http://cdn/${photo}` : null),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.resetAllMocks();
});

async function load(profileId = 7, post: unknown = samplePost) {
  mock(postApi.getPost).mockResolvedValue(ok({ post }));
  const user = userEvent.setup();
  const view = renderWithStore(<DetailPage />, withProfile(profileId));
  await screen.findByText(/Halo kampus|Komentar/);
  await screen.findByText("Halo kampus");
  return { user, ...view };
}

const confirmWith = (answer: boolean) => vi.spyOn(window, "confirm").mockReturnValue(answer);

describe("DetailPage: keadaan awal", () => {
  it("menampilkan status memuat", async () => {
    mock(postApi.getPost).mockReturnValue(new Promise(() => {}));
    renderWithStore(<DetailPage />);
    expect(await screen.findByText("Memuat postingan…")).toBeInTheDocument();
  });

  it("menampilkan pesan bila postingan tidak ditemukan", async () => {
    mock(postApi.getPost).mockResolvedValue(fail("Tidak ada"));
    renderWithStore(<DetailPage />);
    expect(await screen.findByText("Postingan tidak ditemukan.")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Kembali ke beranda" })).toHaveAttribute("href", "/");
  });
});

describe("DetailPage: tampilan", () => {
  it("menampilkan postingan milik sendiri lengkap dengan aksi pemilik", async () => {
    await load();
    expect(screen.getByAltText("Sampul postingan")).toHaveAttribute("src", "http://cdn/c.png");
    expect(screen.getByRole("button", { name: "Batal suka (2)" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Ubah" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Ubah sampul" })).toBeInTheDocument();
    expect(screen.getAllByRole("button", { name: "Hapus" })).toHaveLength(2);
    expect(screen.getByRole("heading", { name: "Komentar (1)" })).toBeInTheDocument();
    expect(screen.getByText("Mantap")).toBeInTheDocument();
  });

  it("menyembunyikan aksi pemilik pada postingan orang lain", async () => {
    await load(99);
    expect(screen.getByRole("button", { name: "Suka (2)" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Ubah" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Hapus" })).not.toBeInTheDocument();
  });

  it("menangani postingan tanpa sampul dan tanpa komentar", async () => {
    await load(7, { ...samplePost, cover: null, comments: [], total_comments: 0 });
    expect(screen.queryByAltText("Sampul postingan")).not.toBeInTheDocument();
    expect(screen.getByText("Belum ada komentar.")).toBeInTheDocument();
  });

  it("hanya menampilkan tombol hapus pada komentar milik sendiri", async () => {
    await load(7, {
      ...samplePost,
      comments: [
        { id: 6, user_id: 8, comment: "Dari Sari", author: { id: 8, name: "Sari" } },
        { id: 9, comment: "Anonim" },
      ],
    });
    expect(screen.getByText("Dari Sari")).toBeInTheDocument();
    expect(screen.getByText("Anonim")).toBeInTheDocument();
    expect(screen.getAllByRole("button", { name: "Hapus" })).toHaveLength(1);
  });
});

describe("DetailPage: suka", () => {
  it("membatalkan suka lalu memuat ulang", async () => {
    mock(postApi.likePost).mockResolvedValue(ok());
    const { user } = await load();
    await user.click(screen.getByRole("button", { name: "Batal suka (2)" }));
    expect(postApi.likePost).toHaveBeenCalledWith(1, 0);
    await waitFor(() => expect(postApi.getPost).toHaveBeenCalledTimes(2));
  });

  it("memberi suka bila belum menyukai", async () => {
    mock(postApi.likePost).mockResolvedValue(ok());
    const { user } = await load(99);
    await user.click(screen.getByRole("button", { name: "Suka (2)" }));
    expect(postApi.likePost).toHaveBeenCalledWith(1, 1);
  });

  it("tidak memuat ulang saat gagal", async () => {
    mock(postApi.likePost).mockResolvedValue(fail("Gagal"));
    const { user } = await load();
    await user.click(screen.getByRole("button", { name: "Batal suka (2)" }));
    await waitFor(() => expect(postApi.likePost).toHaveBeenCalled());
    expect(postApi.getPost).toHaveBeenCalledTimes(1);
  });
});

describe("DetailPage: komentar", () => {
  it("menolak komentar kosong", async () => {
    const { user } = await load();
    await user.click(screen.getByRole("button", { name: "Kirim komentar" }));
    expect(screen.getByText("Komentar tidak boleh kosong")).toBeInTheDocument();
    expect(postApi.addComment).not.toHaveBeenCalled();
  });

  it("mengirim komentar, mengosongkan kolom, lalu memuat ulang", async () => {
    mock(postApi.addComment).mockResolvedValue(ok());
    const { user } = await load();
    const field = screen.getByLabelText("Tulis komentar");
    await user.type(field, "Keren");
    await user.click(screen.getByRole("button", { name: "Kirim komentar" }));
    await waitFor(() => expect(field).toHaveValue(""));
    expect(postApi.addComment).toHaveBeenCalledWith(1, "Keren");
    expect(postApi.getPost).toHaveBeenCalledTimes(2);
  });

  it("mempertahankan isi kolom saat pengiriman gagal", async () => {
    mock(postApi.addComment).mockResolvedValue(fail("Gagal"));
    const { user } = await load();
    const field = screen.getByLabelText("Tulis komentar");
    await user.type(field, "Keren");
    await user.click(screen.getByRole("button", { name: "Kirim komentar" }));
    await waitFor(() => expect(postApi.addComment).toHaveBeenCalled());
    expect(field).toHaveValue("Keren");
  });

  it("menghapus komentar sendiri setelah konfirmasi", async () => {
    mock(postApi.deleteComment).mockResolvedValue(ok());
    confirmWith(true);
    const { user } = await load();
    await user.click(screen.getAllByRole("button", { name: "Hapus" })[1]);
    expect(postApi.deleteComment).toHaveBeenCalledWith(1);
    await waitFor(() => expect(postApi.getPost).toHaveBeenCalledTimes(2));
  });

  it("membatalkan penghapusan komentar bila tidak dikonfirmasi", async () => {
    confirmWith(false);
    const { user } = await load();
    await user.click(screen.getAllByRole("button", { name: "Hapus" })[1]);
    expect(postApi.deleteComment).not.toHaveBeenCalled();
  });

  it("tidak memuat ulang saat penghapusan komentar gagal", async () => {
    mock(postApi.deleteComment).mockResolvedValue(fail("Gagal"));
    confirmWith(true);
    const { user } = await load();
    await user.click(screen.getAllByRole("button", { name: "Hapus" })[1]);
    await waitFor(() => expect(postApi.deleteComment).toHaveBeenCalled());
    expect(postApi.getPost).toHaveBeenCalledTimes(1);
  });
});

describe("DetailPage: menghapus postingan", () => {
  it("menghapus lalu kembali ke beranda", async () => {
    mock(postApi.deletePost).mockResolvedValue(ok());
    confirmWith(true);
    const { user } = await load();
    await user.click(screen.getAllByRole("button", { name: "Hapus" })[0]);
    await waitFor(() => expect(nav.replace).toHaveBeenCalledWith("/"));
    expect(postApi.deletePost).toHaveBeenCalledWith(1);
  });

  it("tidak menghapus bila tidak dikonfirmasi", async () => {
    confirmWith(false);
    const { user } = await load();
    await user.click(screen.getAllByRole("button", { name: "Hapus" })[0]);
    expect(postApi.deletePost).not.toHaveBeenCalled();
  });

  it("tetap di halaman saat penghapusan gagal", async () => {
    mock(postApi.deletePost).mockResolvedValue(fail("Gagal"));
    confirmWith(true);
    const { user } = await load();
    await user.click(screen.getAllByRole("button", { name: "Hapus" })[0]);
    await waitFor(() => expect(postApi.deletePost).toHaveBeenCalled());
    expect(nav.replace).not.toHaveBeenCalled();
  });
});

describe("DetailPage: modal pemilik", () => {
  it("mengubah deskripsi lewat modal lalu memuat ulang", async () => {
    mock(postApi.changePost).mockResolvedValue(ok());
    const { user } = await load();
    await user.click(screen.getByRole("button", { name: "Ubah" }));
    expect(screen.getByRole("dialog", { name: "Ubah postingan" })).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "Simpan perubahan" }));
    await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument());
    expect(postApi.changePost).toHaveBeenCalledWith(1, "Halo kampus");
    expect(postApi.getPost).toHaveBeenCalledTimes(2);
  });

  it("menutup modal ubah tanpa menyimpan", async () => {
    const { user } = await load();
    await user.click(screen.getByRole("button", { name: "Ubah" }));
    await user.click(screen.getByRole("button", { name: "Tutup" }));
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  });

  it("mengganti sampul lewat modal lalu memuat ulang", async () => {
    mock(postApi.changePostCover).mockResolvedValue(ok());
    const { user } = await load();
    await user.click(screen.getByRole("button", { name: "Ubah sampul" }));
    expect(screen.getByRole("dialog", { name: "Ubah sampul" })).toBeInTheDocument();
    await user.upload(
      screen.getByLabelText("Pilih gambar baru"),
      new File(["x"], "a.png", { type: "image/png" }),
    );
    await user.click(screen.getByRole("button", { name: "Unggah sampul" }));
    await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument());
    expect(postApi.getPost).toHaveBeenCalledTimes(2);
  });

  it("menutup modal sampul tanpa menyimpan", async () => {
    const { user } = await load();
    await user.click(screen.getByRole("button", { name: "Ubah sampul" }));
    await user.click(screen.getByRole("button", { name: "Tutup" }));
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  });
});
'@

Write-Host ""
Write-Host "Langkah 10 selesai. Jalankan: npm.cmd run test" -ForegroundColor Cyan