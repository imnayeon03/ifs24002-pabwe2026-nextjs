import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { DELCOM_BASEURL } from "@/lib/config";
import { apiFetch, getAccessToken, putAccessToken, removeAccessToken } from "./apiHelper";

const fetchMock = vi.fn();
const respond = (data: unknown) => fetchMock.mockResolvedValue({ json: async () => data });
const lastCall = () => fetchMock.mock.calls[0] as [URL, { method: string; headers: Record<string, string>; body: unknown }];

beforeEach(() => {
  localStorage.clear();
  fetchMock.mockReset();
  vi.stubGlobal("fetch", fetchMock);
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("token", () => {
  it("menyimpan, membaca, dan menghapus token", () => {
    expect(getAccessToken()).toBeNull();
    putAccessToken("abc");
    expect(getAccessToken()).toBe("abc");
    removeAccessToken();
    expect(getAccessToken()).toBeNull();
  });

  it("mengembalikan null bila dijalankan di luar browser", () => {
    vi.stubGlobal("window", undefined);
    expect(getAccessToken()).toBeNull();
  });
});

describe("apiFetch", () => {
  it("mengirim GET tanpa opsi apa pun", async () => {
    respond({ status: "success", message: "ok" });
    const result = await apiFetch("/users");
    const [url, init] = lastCall();
    expect(String(url)).toBe(`${DELCOM_BASEURL}/users`);
    expect(init.method).toBe("GET");
    expect(init.headers).toEqual({ Accept: "application/json" });
    expect(init.body).toBeUndefined();
    expect(result).toEqual({ status: "success", message: "ok" });
  });

  it("menyertakan query dan melewati nilai undefined", async () => {
    respond({ status: "success", message: "ok" });
    await apiFetch("/posts", { query: { is_me: 1, skip: undefined } });
    expect(String(lastCall()[0])).toBe(`${DELCOM_BASEURL}/posts?is_me=1`);
  });

  it("menyertakan token bila tersedia", async () => {
    respond({ status: "success", message: "ok" });
    putAccessToken("abc");
    await apiFetch("/users/me");
    expect(lastCall()[1].headers.Authorization).toBe("Bearer abc");
  });

  it("tidak menyertakan token bila auth dimatikan", async () => {
    respond({ status: "success", message: "ok" });
    putAccessToken("abc");
    await apiFetch("/auth/login", { method: "POST", auth: false });
    expect(lastCall()[1].headers.Authorization).toBeUndefined();
  });

  it("tidak menyertakan token bila belum login", async () => {
    respond({ status: "success", message: "ok" });
    await apiFetch("/users/me");
    expect(lastCall()[1].headers.Authorization).toBeUndefined();
  });

  it("mengirim body JSON", async () => {
    respond({ status: "success", message: "ok" });
    await apiFetch("/posts", { method: "POST", body: { description: "Halo" } });
    const init = lastCall()[1];
    expect(init.method).toBe("POST");
    expect(init.headers["Content-Type"]).toBe("application/json");
    expect(init.body).toBe(JSON.stringify({ description: "Halo" }));
  });

  it("mengirim FormData apa adanya tanpa Content-Type", async () => {
    respond({ status: "success", message: "ok" });
    const form = new FormData();
    form.append("cover", new File(["x"], "a.png"));
    await apiFetch("/posts/1/cover", { method: "POST", body: form });
    const init = lastCall()[1];
    expect(init.body).toBe(form);
    expect(init.headers["Content-Type"]).toBeUndefined();
  });

  it("mengembalikan pesan gagal saat jaringan bermasalah", async () => {
    fetchMock.mockRejectedValue(new Error("offline"));
    const result = await apiFetch("/users");
    expect(result).toEqual({ status: "fail", message: "Tidak dapat terhubung ke server" });
  });
});