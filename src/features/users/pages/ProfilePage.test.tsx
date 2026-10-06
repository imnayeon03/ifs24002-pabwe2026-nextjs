import { fireEvent, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, me, ok, renderWithStore } from "@/test/utils";
import * as userApi from "../api/userApi";
import ProfilePage from "./ProfilePage";

vi.mock("../api/userApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
  showWarningDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.resetAllMocks();
  mock(userApi.getProfile).mockResolvedValue(ok({ user: me }));
});

async function setup() {
  const user = userEvent.setup();
  renderWithStore(<ProfilePage />);
  await waitFor(() => expect(screen.getByLabelText("Nama")).toHaveValue("Budi"));
  return user;
}

describe("ProfilePage: tampilan awal", () => {
  it("menampilkan status memuat bila profil belum ada", async () => {
    mock(userApi.getProfile).mockReturnValue(new Promise(() => {}));
    renderWithStore(<ProfilePage />, {});
    expect(await screen.findByText("Memuat profilâ€¦")).toBeInTheDocument();
  });

  it("mengisi form dengan data akun", async () => {
    await setup();
    expect(screen.getByLabelText("Email")).toHaveValue("budi@mail.id");
  });
});

describe("ProfilePage: data akun", () => {
  it("menolak nama dan email yang tidak valid", async () => {
    const user = await setup();
    const name = screen.getByLabelText("Nama");
    const email = screen.getByLabelText("Email");
    await user.clear(name);
    await user.type(name, "ab");
    await user.clear(email);
    await user.type(email, "salah");
    await user.click(screen.getByRole("button", { name: "Simpan perubahan" }));
    expect(screen.getByText("Nama minimal 3 karakter")).toBeInTheDocument();
    expect(screen.getByText("Format email tidak valid")).toBeInTheDocument();
    expect(userApi.changeProfile).not.toHaveBeenCalled();
  });

  it("menyimpan perubahan yang valid", async () => {
    mock(userApi.changeProfile).mockResolvedValue(ok());
    const user = await setup();
    const name = screen.getByLabelText("Nama");
    await user.clear(name);
    await user.type(name, "Budi Baru");
    await user.click(screen.getByRole("button", { name: "Simpan perubahan" }));
    await waitFor(() =>
      expect(userApi.changeProfile).toHaveBeenCalledWith({ name: "Budi Baru", email: "budi@mail.id" }),
    );
  });
});

describe("ProfilePage: foto", () => {
  const file = () => new File(["x"], "a.png", { type: "image/png" });

  it("memperingatkan bila belum memilih foto", async () => {
    const user = await setup();
    await user.click(screen.getByRole("button", { name: "Unggah foto" }));
    expect(toolsHelper.showWarningDialog).toHaveBeenCalledWith("Pilih foto terlebih dahulu");
    expect(userApi.changeProfilePhoto).not.toHaveBeenCalled();
  });

  it("mengunggah foto yang dipilih", async () => {
    mock(userApi.changeProfilePhoto).mockResolvedValue(ok());
    const user = await setup();
    const chosen = file();
    await user.upload(screen.getByLabelText("Pilih foto baru"), chosen);
    await user.click(screen.getByRole("button", { name: "Unggah foto" }));
    await waitFor(() => expect(userApi.changeProfilePhoto).toHaveBeenCalledWith(chosen));
  });

  it("mempertahankan pilihan saat unggahan gagal", async () => {
    mock(userApi.changeProfilePhoto).mockResolvedValue(fail("Gagal"));
    const user = await setup();
    await user.upload(screen.getByLabelText("Pilih foto baru"), file());
    await user.click(screen.getByRole("button", { name: "Unggah foto" }));
    await waitFor(() => expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal"));
  });

  it("menganggap tidak ada foto bila daftar file kosong", async () => {
    const user = await setup();
    fireEvent.change(screen.getByLabelText("Pilih foto baru"), { target: { files: [] } });
    await user.click(screen.getByRole("button", { name: "Unggah foto" }));
    expect(toolsHelper.showWarningDialog).toHaveBeenCalled();
  });
});

describe("ProfilePage: kata sandi", () => {
  const fill = async (
    user: ReturnType<typeof userEvent.setup>,
    current: string,
    next: string,
    confirm: string,
  ) => {
    if (current) await user.type(screen.getByLabelText("Kata sandi saat ini"), current);
    if (next) await user.type(screen.getByLabelText("Kata sandi baru"), next);
    if (confirm) await user.type(screen.getByLabelText("Ulangi kata sandi baru"), confirm);
    await user.click(screen.getByRole("button", { name: "Ubah kata sandi" }));
  };

  it("menolak kata sandi yang terlalu pendek", async () => {
    const user = await setup();
    await fill(user, "", "", "");
    expect(screen.getByText("Kata sandi saat ini minimal 6 karakter")).toBeInTheDocument();
    expect(screen.getByText("Kata sandi baru minimal 6 karakter")).toBeInTheDocument();
    expect(userApi.changePassword).not.toHaveBeenCalled();
  });

  it("menolak konfirmasi yang berbeda", async () => {
    const user = await setup();
    await fill(user, "lama123", "baru123", "beda123");
    expect(screen.getByText("Konfirmasi tidak sama")).toBeInTheDocument();
    expect(userApi.changePassword).not.toHaveBeenCalled();
  });

  it("mengubah kata sandi lalu mengosongkan kolom", async () => {
    mock(userApi.changePassword).mockResolvedValue(ok());
    const user = await setup();
    await fill(user, "lama123", "baru123", "baru123");
    await waitFor(() => expect(screen.getByLabelText("Kata sandi baru")).toHaveValue(""));
    expect(userApi.changePassword).toHaveBeenCalledWith({
      password: "lama123",
      new_password: "baru123",
      new_password_confirmation: "baru123",
    });
  });

  it("mempertahankan isi kolom saat gagal", async () => {
    mock(userApi.changePassword).mockResolvedValue(fail("Salah"));
    const user = await setup();
    await fill(user, "lama123", "baru123", "baru123");
    await waitFor(() => expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Salah"));
    expect(screen.getByLabelText("Kata sandi baru")).toHaveValue("baru123");
  });
});