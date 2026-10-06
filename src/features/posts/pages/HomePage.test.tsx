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