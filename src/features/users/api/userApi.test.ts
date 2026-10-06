import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiFetch } from "@/helpers/apiHelper";
import * as api from "./userApi";

vi.mock("@/helpers/apiHelper", () => ({ apiFetch: vi.fn() }));

const fetchMock = vi.mocked(apiFetch);

beforeEach(() => {
  fetchMock.mockReset();
});

describe("userApi", () => {
  it("getUsers", () => {
    api.getUsers();
    expect(fetchMock).toHaveBeenCalledWith("/users");
  });

  it("getProfile", () => {
    api.getProfile();
    expect(fetchMock).toHaveBeenCalledWith("/users/me");
  });

  it("changeProfile", () => {
    const payload = { name: "Budi", email: "budi@mail.id" };
    api.changeProfile(payload);
    expect(fetchMock).toHaveBeenCalledWith("/users/me", { method: "PUT", body: payload });
  });

  it("changeProfilePhoto mengirim FormData", () => {
    api.changeProfilePhoto(new File(["x"], "a.png"));
    const [path, options] = fetchMock.mock.calls[0] as [string, { method: string; body: FormData }];
    expect(path).toBe("/users/me/photo");
    expect(options.method).toBe("POST");
    expect((options.body.get("photo") as File).name).toBe("a.png");
  });

  it("changePassword", () => {
    const payload = { password: "lama123", new_password: "baru123", new_password_confirmation: "baru123" };
    api.changePassword(payload);
    expect(fetchMock).toHaveBeenCalledWith("/users/password", { method: "PUT", body: payload });
  });
});