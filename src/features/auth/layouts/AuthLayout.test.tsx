import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { getAccessToken } from "@/helpers/apiHelper";
import AuthLayout from "./AuthLayout";

const nav = vi.hoisted(() => ({ replace: vi.fn() }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ replace: nav.replace }) }));
vi.mock("@/helpers/apiHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  getAccessToken: vi.fn(),
}));

beforeEach(() => {
  vi.resetAllMocks();
});

describe("AuthLayout", () => {
  it("menampilkan konten bila belum login", () => {
    vi.mocked(getAccessToken).mockReturnValue(null as never);
    render(<AuthLayout><p>Isi form</p></AuthLayout>);
    expect(screen.getByText("Isi form")).toBeInTheDocument();
    expect(nav.replace).not.toHaveBeenCalled();
  });

  it("mengarahkan ke beranda bila sudah login", () => {
    vi.mocked(getAccessToken).mockReturnValue("token" as never);
    render(<AuthLayout><p>Isi form</p></AuthLayout>);
    expect(nav.replace).toHaveBeenCalledWith("/");
  });
});