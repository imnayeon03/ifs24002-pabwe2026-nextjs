import Swal from "sweetalert2";
import { DELCOM_BASEURL } from "@/lib/config";

export const showSuccessDialog = (message: string) =>
  Swal.fire({ icon: "success", title: "Berhasil", text: message, confirmButtonColor: "#1e1b4b" });

export const showErrorDialog = (message: string) =>
  Swal.fire({ icon: "error", title: "Gagal", text: message, confirmButtonColor: "#1e1b4b" });

export const showWarningDialog = (message: string) =>
  Swal.fire({ icon: "warning", title: "Perhatian", text: message, confirmButtonColor: "#1e1b4b" });

export const showConfirmDialog = async (title: string, text: string): Promise<boolean> => {
  const result = await Swal.fire({
    icon: "question",
    title,
    text,
    showCancelButton: true,
    confirmButtonText: "Ya",
    cancelButtonText: "Batal",
    confirmButtonColor: "#1e1b4b",
  });
  return result.isConfirmed;
};

export const formatDate = (value: string): string =>
  new Date(value).toLocaleString("id-ID", { dateStyle: "long", timeStyle: "short" });

export const resolveMediaUrl = (path?: string | null): string | null => {
  if (!path) return null;
  if (/^https?:\/\//.test(path)) return path;
  return `${new URL(DELCOM_BASEURL).origin}/${path.replace(/^\//, "")}`;
};