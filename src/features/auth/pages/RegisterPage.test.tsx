import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, ok, renderWithStore } from "@/test/utils";
import * as authApi from "../api/authApi";
import RegisterPage from "./RegisterPage";

const nav = vi.hoisted(() => ({ replace: vi.fn(), push: vi.fn() }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: nav.replace, push: nav.push }),
}));
vi.mock("../api/authApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.resetAllMocks();
});

async function fill(confirm = "rahasia1") {
  const user = userEvent.setup();
  renderWithStore(<RegisterPage />, {});
  await user.type(screen.getByLabelText("Nama lengkap"), "  Budi Santoso ");
  await user.type(screen.getByLabelText("Email"), "budi@mail.id");
  await user.type(screen.getByLabelText("Kata sandi"), "rahasia1");
  await user.type(screen.getByLabelText("Ulangi kata sandi"), confirm);
  await user.click(screen.getByRole("button", { name: "Daftar" }));
  return user;
}

describe("RegisterPage", () => {
  it("menolak isian kosong", async () => {
    const user = userEvent.setup();
    renderWithStore(<RegisterPage />, {});
    await user.click(screen.getByRole("button", { name: "Daftar" }));
    expect(screen.getByText("Nama minimal 3 karakter")).toBeInTheDocument();
    expect(screen.getByText("Format email tidak valid")).toBeInTheDocument();
    expect(screen.getByText("Kata sandi minimal 6 karakter")).toBeInTheDocument();
    expect(authApi.register).not.toHaveBeenCalled();
  });

  it("menolak konfirmasi kata sandi yang berbeda", async () => {
    await fill("beda1234");
    expect(screen.getByText("Konfirmasi kata sandi tidak sama")).toBeInTheDocument();
    expect(authApi.register).not.toHaveBeenCalled();
  });

  it("mendaftar lalu menuju halaman login", async () => {
    mock(authApi.register).mockResolvedValue(ok());
    await fill();
    await waitFor(() => expect(nav.push).toHaveBeenCalledWith("/auth/login"));
    expect(authApi.register).toHaveBeenCalledWith({
      name: "Budi Santoso",
      email: "budi@mail.id",
      password: "rahasia1",
    });
  });

  it("tetap di halaman saat pendaftaran gagal", async () => {
    mock(authApi.register).mockResolvedValue(fail("Email dipakai"));
    await fill();
    await waitFor(() => expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Email dipakai"));
    expect(nav.push).not.toHaveBeenCalled();
  });

  it("menampilkan status memproses", async () => {
    mock(authApi.register).mockReturnValue(new Promise(() => {}));
    await fill();
    expect(await screen.findByRole("button", { name: "Memprosesâ€¦" })).toBeDisabled();
  });

  it("menyediakan tautan ke halaman masuk", () => {
    renderWithStore(<RegisterPage />, {});
    expect(screen.getByRole("link", { name: "Masuk" })).toHaveAttribute("href", "/auth/login");
  });
});