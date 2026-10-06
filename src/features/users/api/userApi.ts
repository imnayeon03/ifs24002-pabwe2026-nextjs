import { apiFetch } from "@/helpers/apiHelper";
import type { ChangePasswordPayload, ProfilePayload } from "@/types/action";
import type { User } from "@/types";

export const getUsers = () => apiFetch<{ users: User[] }>("/users");

export const getProfile = () => apiFetch<{ user: User }>("/users/me");

export const changeProfile = (payload: ProfilePayload) =>
  apiFetch<{ user: User }>("/users/me", { method: "PUT", body: payload });

export const changeProfilePhoto = (photo: File) => {
  const form = new FormData();
  form.append("photo", photo);
  return apiFetch("/users/me/photo", { method: "POST", body: form });
};

// Sesuai dokumentasi Delcom: PUT /users/password
export const changePassword = (payload: ChangePasswordPayload) =>
  apiFetch("/users/password", { method: "PUT", body: payload });