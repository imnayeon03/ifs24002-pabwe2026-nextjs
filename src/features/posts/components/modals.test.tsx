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