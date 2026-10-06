import { apiFetch } from "@/helpers/apiHelper";
import type { LoginPayload, RegisterPayload } from "@/types/action";
import type { User } from "@/types";

export const login = (payload: LoginPayload) =>
  apiFetch<{ user: User; token: string }>("/auth/login", {
    method: "POST",
    body: payload,
    auth: false,
  });

export const register = (payload: RegisterPayload) =>
  apiFetch("/auth/register", { method: "POST", body: payload, auth: false });

export const logout = () => apiFetch("/auth/logout", { method: "POST" });