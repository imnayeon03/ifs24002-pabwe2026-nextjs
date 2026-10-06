import Swal from "sweetalert2";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { DELCOM_BASEURL } from "@/lib/config";
import {
  formatDate,
  resolveMediaUrl,
  showConfirmDialog,
  showErrorDialog,
  showSuccessDialog,
  showWarningDialog,
} from "./toolsHelper";

vi.mock("sweetalert2", () => ({ default: { fire: vi.fn() } }));

const fire = vi.mocked(Swal.fire);
const origin = new URL(DELCOM_BASEURL).origin;

beforeEach(() => {
  fire.mockReset();
});

describe("dialog", () => {
  it("showSuccessDialog", () => {
    showSuccessDialog("Tersimpan");
    expect(fire).toHaveBeenCalledWith(expect.objectContaining({ icon: "success", text: "Tersimpan" }));
  });

  it("showErrorDialog", () => {
    showErrorDialog("Gagal");
    expect(fire).toHaveBeenCalledWith(expect.objectContaining({ icon: "error", text: "Gagal" }));
  });

  it("showWarningDialog", () => {
    showWarningDialog("Hati-hati");
    expect(fire).toHaveBeenCalledWith(expect.objectContaining({ icon: "warning", text: "Hati-hati" }));
  });

  it("showConfirmDialog mengembalikan pilihan pengguna", async () => {
    fire.mockResolvedValueOnce({ isConfirmed: true } as never);
    expect(await showConfirmDialog("Hapus?", "Yakin?")).toBe(true);
    expect(fire).toHaveBeenCalledWith(
      expect.objectContaining({ icon: "question", title: "Hapus?", text: "Yakin?", showCancelButton: true }),
    );

    fire.mockResolvedValueOnce({ isConfirmed: false } as never);
    expect(await showConfirmDialog("Hapus?", "Yakin?")).toBe(false);
  });
});

describe("formatDate", () => {
  it("memformat tanggal ke bahasa Indonesia", () => {
    expect(formatDate("2026-01-05T10:00:00Z")).toContain("2026");
  });
});

describe("resolveMediaUrl", () => {
  it("mengembalikan null untuk nilai kosong", () => {
    expect(resolveMediaUrl()).toBeNull();
    expect(resolveMediaUrl(null)).toBeNull();
    expect(resolveMediaUrl("")).toBeNull();
  });

  it("membiarkan URL absolut", () => {
    expect(resolveMediaUrl("https://cdn.test/a.png")).toBe("https://cdn.test/a.png");
    expect(resolveMediaUrl("http://cdn.test/a.png")).toBe("http://cdn.test/a.png");
  });

  it("menambahkan origin untuk path relatif", () => {
    expect(resolveMediaUrl("uploads/a.png")).toBe(`${origin}/uploads/a.png`);
    expect(resolveMediaUrl("/uploads/a.png")).toBe(`${origin}/uploads/a.png`);
  });
});