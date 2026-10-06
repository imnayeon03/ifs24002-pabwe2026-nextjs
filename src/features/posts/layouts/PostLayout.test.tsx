import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { asyncLogout } from "@/features/auth/states/action";
import * as userApi from "@/features/users/api/userApi";
import { getAccessToken, removeAccessToken } from "@/helpers/apiHelper";
import { fail, me, ok, renderWithStore } from "@/test/utils";
import PostLayout from "./PostLayout";

const nav = vi.hoisted(() => ({ replace: vi.fn() }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: nav.replace }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));
vi.mock("@/features/users/api/userApi");
vi.mock("@/features/auth/states/action", async (importOriginal) => {
  const original = await importOriginal<Record<string, unknown>>();
  // Salin properti thunk asli (pending, fulfilled, rejected) agar reducer auth tetap bisa dibuat
  return { ...original, asyncLogout: Object.assign(vi.fn(), original.asyncLogout as object) };
});
vi.mock("@/helpers/apiHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  getAccessToken: vi.fn(),
  removeAccessToken: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

const renderLayout = () =>
  renderWithStore(
    <PostLayout>
      <p>Konten halaman</p>
    </PostLayout>,
    {},
  );

beforeEach(() => {
  vi.resetAllMocks();
  mock(asyncLogout).mockReturnValue({ type: "test/logout" });
  mock(getAccessToken).mockReturnValue("token");
  mock(userApi.getProfile).mockResolvedValue(ok({ user: me }));
});

describe("PostLayout: route guard", () => {
  it("mengarahkan ke login bila tidak ada token", async () => {
    mock(getAccessToken).mockReturnValue(null);
    renderLayout();
    await waitFor(() => expect(nav.replace).toHaveBeenCalledWith("/auth/login"));
    expect(screen.getByText("Memuatâ€¦")).toBeInTheDocument();
    expect(userApi.getProfile).not.toHaveBeenCalled();
  });

  it("menghapus token dan ke login bila profil gagal dimuat", async () => {
    mock(userApi.getProfile).mockResolvedValue(fail("Token salah"));
    renderLayout();
    await waitFor(() => expect(nav.replace).toHaveBeenCalledWith("/auth/login"));
    expect(removeAccessToken).toHaveBeenCalled();
  });

  it("menampilkan halaman setelah profil berhasil dimuat", async () => {
    renderLayout();
    expect(await screen.findByText("Konten halaman")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Lewati ke konten utama" })).toBeInTheDocument();
    expect(nav.replace).not.toHaveBeenCalled();
  });

  it("tidak melakukan apa pun bila dilepas sebelum verifikasi selesai", async () => {
    let resolve!: (value: unknown) => void;
    mock(userApi.getProfile).mockReturnValue(new Promise((r) => (resolve = r)));
    const { unmount } = renderLayout();
    unmount();
    resolve(ok({ user: me }));
    await new Promise((r) => setTimeout(r, 0));
    expect(nav.replace).not.toHaveBeenCalled();
  });
});

describe("PostLayout: interaksi", () => {
  it("keluar lewat menu akun", async () => {
    const user = userEvent.setup();
    renderLayout();
    await screen.findByText("Konten halaman");
    await user.click(screen.getByRole("button", { name: "Menu akun" }));
    await user.click(screen.getByRole("button", { name: "Keluar" }));
    expect(asyncLogout).toHaveBeenCalled();
    await waitFor(() => expect(nav.replace).toHaveBeenCalledWith("/auth/login"));
  });

  it("membuka dan menutup sidebar", async () => {
    const user = userEvent.setup();
    renderLayout();
    await screen.findByText("Konten halaman");
    const aside = screen.getByLabelText("Menu samping");
    await user.click(screen.getByRole("button", { name: "Buka menu navigasi" }));
    expect(aside).toHaveClass("visible");
    await user.click(screen.getByRole("button", { name: "Tutup menu navigasi" }));
    expect(aside).not.toHaveClass("visible");
  });
});