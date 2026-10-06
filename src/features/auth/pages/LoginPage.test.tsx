import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, ok, renderWithStore } from "@/test/utils";
import * as authApi from "../api/authApi";
import LoginPage from "./LoginPage";

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

async function fillAndSubmit() {
  const user = userEvent.setup();
  renderWithStore(<LoginPage />, {});
  await user.type(screen.getByLabelText("Email"), "budi@mail.id");
  await user.type(screen.getByLabelText("Kata sandi"), "rahasia1");
  await user.click(screen.getByRole("button", { name: "Masuk" }));
  return user;
}

describe("LoginPage", () => {
  it("menolak email dan kata sandi yang tidak valid", async () => {
    const user = userEvent.setup();
    renderWithStore(<LoginPage />, {});
    await user.click(screen.getByRole("button", { name: "Masuk" }));
    expect(screen.getByText("Format email tidak valid")).toBeInTheDocument();
    expect(screen.getByText("Kata sandi minimal 6 karakter")).toBeInTheDocument();
    expect(authApi.login).not.toHaveBeenCalled();
  });

  it("menampilkan dan menyembunyikan kata sandi", async () => {
    const user = userEvent.setup();
    renderWithStore(<LoginPage />, {});
    const field = screen.getByLabelText("Kata sandi");
    expect(field).toHaveAttribute("type", "password");
    await user.click(screen.getByRole("button", { name: "Tampilkan kata sandi" }));
    expect(field).toHaveAttribute("type", "text");
    await user.click(screen.getByRole("button", { name: "Sembunyikan kata sandi" }));
    expect(field).toHaveAttribute("type", "password");
  });

  it("masuk lalu menuju beranda", async () => {
    mock(authApi.login).mockResolvedValue(ok({ token: "t" }));
    await fillAndSubmit();
    await waitFor(() => expect(nav.replace).toHaveBeenCalledWith("/"));
    expect(authApi.login).toHaveBeenCalledWith({ email: "budi@mail.id", password: "rahasia1" });
  });

  it("tetap di halaman saat login gagal", async () => {
    mock(authApi.login).mockResolvedValue(fail("Salah"));
    await fillAndSubmit();
    await waitFor(() => expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Salah"));
    expect(nav.replace).not.toHaveBeenCalled();
  });

  it("menampilkan status memproses", async () => {
    mock(authApi.login).mockReturnValue(new Promise(() => {}));
    await fillAndSubmit();
    expect(await screen.findByRole("button", { name: "Memprosesâ€¦" })).toBeDisabled();
  });

  it("menyediakan tautan ke halaman daftar", () => {
    renderWithStore(<LoginPage />, {});
    expect(screen.getByRole("link", { name: "Daftar sekarang" })).toHaveAttribute("href", "/auth/register");
  });
});