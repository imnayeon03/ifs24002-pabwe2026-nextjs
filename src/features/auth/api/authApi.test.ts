import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiFetch } from "@/helpers/apiHelper";
import * as api from "./authApi";

vi.mock("@/helpers/apiHelper", () => ({ apiFetch: vi.fn() }));

const fetchMock = vi.mocked(apiFetch);

beforeEach(() => {
  fetchMock.mockReset();
});

describe("authApi", () => {
  it("login tanpa token", () => {
    const payload = { email: "budi@mail.id", password: "rahasia1" };
    api.login(payload);
    expect(fetchMock).toHaveBeenCalledWith("/auth/login", { method: "POST", body: payload, auth: false });
  });

  it("register tanpa token", () => {
    const payload = { name: "Budi", email: "budi@mail.id", password: "rahasia1" };
    api.register(payload);
    expect(fetchMock).toHaveBeenCalledWith("/auth/register", { method: "POST", body: payload, auth: false });
  });

  it("logout dengan token", () => {
    api.logout();
    expect(fetchMock).toHaveBeenCalledWith("/auth/logout", { method: "POST" });
  });
});