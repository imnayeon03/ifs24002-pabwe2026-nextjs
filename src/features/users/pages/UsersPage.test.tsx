import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { me, ok, renderWithStore } from "@/test/utils";
import * as userApi from "../api/userApi";
import UsersPage from "./UsersPage";

vi.mock("../api/userApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;
const sari = { id: 8, name: "Sari", email: "sari@mail.id", photo: null };

beforeEach(() => {
  vi.resetAllMocks();
  mock(userApi.getUsers).mockResolvedValue(ok({ users: [me, sari] }));
});

describe("UsersPage", () => {
  it("menampilkan daftar pengguna", async () => {
    renderWithStore(<UsersPage />);
    expect(await screen.findByText("Sari")).toBeInTheDocument();
    expect(screen.getByText("Budi")).toBeInTheDocument();
    expect(screen.getByText("sari@mail.id")).toBeInTheDocument();
  });

  it("menampilkan status memuat", async () => {
    mock(userApi.getUsers).mockReturnValue(new Promise(() => {}));
    renderWithStore(<UsersPage />);
    expect(await screen.findByText(/Memuat pengguna/)).toBeInTheDocument();
  });

  it("menyaring pengguna berdasarkan nama atau email", async () => {
    const user = userEvent.setup();
    renderWithStore(<UsersPage />);
    await screen.findByText("Sari");
    const search = screen.getByRole("searchbox", { name: "Cari pengguna" });

    await user.type(search, "sari@");
    expect(screen.queryByText("Budi")).not.toBeInTheDocument();
    expect(screen.getByText("Sari")).toBeInTheDocument();

    await user.clear(search);
    await user.type(search, "zzz");
    expect(screen.getByText("Tidak ada pengguna yang cocok.")).toBeInTheDocument();
  });
});