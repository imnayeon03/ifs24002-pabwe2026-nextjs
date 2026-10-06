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