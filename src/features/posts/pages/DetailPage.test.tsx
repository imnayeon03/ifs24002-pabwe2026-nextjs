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
  await screen.findByText("Halo kampus");
  return { user, ...view };
}

const confirmWith = (answer: boolean) => vi.spyOn(window, "confirm").mockReturnValue(answer);

describe("DetailPage: keadaan awal", () => {
  it("menampilkan status memuat", async () => {
    mock(postApi.getPost).mockReturnValue(new Promise(() => {}));
    renderWithStore(<DetailPage />);
    expect(await screen.findByText(/Memuat postingan/)).toBeInTheDocument();
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
