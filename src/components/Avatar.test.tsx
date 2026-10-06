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