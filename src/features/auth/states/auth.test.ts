import { beforeEach, describe, expect, it, vi } from "vitest";
import { putAccessToken, removeAccessToken } from "@/helpers/apiHelper";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, makeStore, me, ok } from "@/test/utils";
import * as authApi from "../api/authApi";
import { asyncLogin, asyncLogout, asyncRegister } from "./action";

vi.mock("../api/authApi");
vi.mock("@/helpers/apiHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  putAccessToken: vi.fn(),
  removeAccessToken: vi.fn(),
}));
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;
const credentials = { email: "budi@mail.id", password: "rahasia1" };

beforeEach(() => {
  vi.resetAllMocks();
});

describe("asyncLogin", () => {
  it("menyimpan token saat berhasil", async () => {
    mock(authApi.login).mockResolvedValue(ok({ token: "t", user: me }));
    const store = makeStore();
    const action = await store.dispatch(asyncLogin(credentials));
    expect(action.payload).toBe(true);
    expect(putAccessToken).toHaveBeenCalledWith("t");
    expect(store.getState().auth.isAuthLogin).toBe(false);
  });

  it("menampilkan error saat gagal", async () => {
    mock(authApi.login).mockResolvedValue(fail("Salah"));
    const store = makeStore();
    const action = await store.dispatch(asyncLogin(credentials));
    expect(action.payload).toBe(false);
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Salah");
    expect(putAccessToken).not.toHaveBeenCalled();
  });

  it("menganggap respons sukses tanpa data sebagai gagal", async () => {
    mock(authApi.login).mockResolvedValue(ok());
    const store = makeStore();
    const action = await store.dispatch(asyncLogin(credentials));
    expect(action.payload).toBe(false);
  });

  it("mematikan penanda saat ditolak", async () => {
    mock(authApi.login).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(asyncLogin(credentials));
    expect(store.getState().auth.isAuthLogin).toBe(false);
  });
});

describe("asyncRegister", () => {
  const payload = { name: "Budi", ...credentials };

  it("menampilkan dialog sukses", async () => {
    mock(authApi.register).mockResolvedValue(ok());
    const store = makeStore();
    const action = await store.dispatch(asyncRegister(payload));
    expect(action.payload).toBe(true);
    expect(toolsHelper.showSuccessDialog).toHaveBeenCalledWith("Berhasil");
    expect(store.getState().auth.isAuthRegister).toBe(false);
  });

  it("menampilkan error saat gagal", async () => {
    mock(authApi.register).mockResolvedValue(fail("Email dipakai"));
    const store = makeStore();
    const action = await store.dispatch(asyncRegister(payload));
    expect(action.payload).toBe(false);
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Email dipakai");
  });

  it("mematikan penanda saat ditolak", async () => {
    mock(authApi.register).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(asyncRegister(payload));
    expect(store.getState().auth.isAuthRegister).toBe(false);
  });
});

describe("asyncLogout", () => {
  it("menghapus token", async () => {
    mock(authApi.logout).mockResolvedValue(ok());
    const store = makeStore();
    const action = await store.dispatch(asyncLogout());
    expect(action.payload).toBe(true);
    expect(removeAccessToken).toHaveBeenCalled();
    expect(store.getState().auth.isAuthLogout).toBe(false);
  });

  it("mematikan penanda saat ditolak", async () => {
    mock(authApi.logout).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(asyncLogout());
    expect(store.getState().auth.isAuthLogout).toBe(false);
    expect(removeAccessToken).not.toHaveBeenCalled();
  });
});