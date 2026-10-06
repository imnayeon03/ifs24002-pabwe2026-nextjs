import { fireEvent, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { renderWithStore } from "@/test/utils";
import ChangeCoverModal from "./ChangeCoverModal";

vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showWarningDialog: vi.fn(),
}));

describe("ChangeCoverModal: pilihan file dikosongkan", () => {
  it("menganggap tidak ada file bila daftar file kosong", async () => {
    renderWithStore(<ChangeCoverModal postId={1} onClose={vi.fn()} onDone={vi.fn()} />);
    fireEvent.change(screen.getByLabelText("Pilih gambar baru"), { target: { files: [] } });
    await userEvent.setup().click(screen.getByRole("button", { name: "Unggah sampul" }));
    expect(toolsHelper.showWarningDialog).toHaveBeenCalled();
  });
});