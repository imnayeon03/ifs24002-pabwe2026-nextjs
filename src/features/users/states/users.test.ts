/* eslint-disable @typescript-eslint/no-explicit-any */
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as toolsHelper from "@/helpers/toolsHelper";
import { fail, makeStore, me, ok } from "@/test/utils";
import * as userApi from "../api/userApi";
import * as actions from "./action";

vi.mock("../api/userApi");
vi.mock("@/helpers/toolsHelper", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  showErrorDialog: vi.fn(),
  showSuccessDialog: vi.fn(),
}));

const mock = (fn: unknown) => fn as ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.resetAllMocks();
  mock(userApi.getProfile).mockResolvedValue(ok({ user: me }));
});

describe("asyncGetUsers", () => {
  it("memuat daftar pengguna", async () => {
    mock(userApi.getUsers).mockResolvedValue(ok({ users: [me] }));
    const store = makeStore();
    await store.dispatch(actions.asyncGetUsers());
    expect(store.getState().users.users).toHaveLength(1);
    expect(store.getState().users.isUsers).toBe(false);
  });

  it("menampilkan error saat gagal atau tanpa data", async () => {
    mock(userApi.getUsers).mockResolvedValue(fail("Gagal"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetUsers());
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal");

    mock(userApi.getUsers).mockResolvedValue(ok());
    await store.dispatch(actions.asyncGetUsers());
    expect(store.getState().users.users).toEqual([]);
  });

  it("mematikan penanda saat ditolak", async () => {
    mock(userApi.getUsers).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetUsers());
    expect(store.getState().users.isUsers).toBe(false);
  });
});

describe("asyncGetProfile", () => {
  it("memuat profil", async () => {
    const store = makeStore();
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.profile).toEqual(me);
    expect(store.getState().users.isProfile).toBe(false);
  });

  it("tidak menimpa profil lama saat gagal atau tanpa data", async () => {
    const store = makeStore();
    await store.dispatch(actions.asyncGetProfile());

    mock(userApi.getProfile).mockResolvedValue(fail("Token salah"));
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.profile).toEqual(me);

    mock(userApi.getProfile).mockResolvedValue(ok());
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.profile).toEqual(me);
  });

  it("mematikan penanda saat ditolak", async () => {
    mock(userApi.getProfile).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(actions.asyncGetProfile());
    expect(store.getState().users.isProfile).toBe(false);
  });
});

interface Mutation {
  name: string;
  thunk: any;
  api: unknown;
  arg: unknown;
  flag: string;
}

const mutations: Mutation[] = [
  { name: "asyncChangeProfile", thunk: actions.asyncChangeProfile, api: userApi.changeProfile, arg: { name: "Budi", email: "budi@mail.id" }, flag: "isChangeProfile" },
  { name: "asyncChangeProfilePhoto", thunk: actions.asyncChangeProfilePhoto, api: userApi.changeProfilePhoto, arg: new File(["x"], "a.png"), flag: "isChangeProfilePhoto" },
  { name: "asyncChangeProfilePassword", thunk: actions.asyncChangeProfilePassword, api: userApi.changePassword, arg: { password: "lama123", new_password: "baru123", new_password_confirmation: "baru123" }, flag: "isChangeProfilePassword" },
];

describe.each(mutations)("$name", ({ thunk, api, arg, flag }) => {
  it("berhasil", async () => {
    mock(api).mockResolvedValue(ok());
    const store = makeStore();
    await store.dispatch(thunk(arg));
    expect((store.getState().users as any)[flag]).toBe(false);
    expect(toolsHelper.showSuccessDialog).toHaveBeenCalledWith("Berhasil");
  });

  it("gagal", async () => {
    mock(api).mockResolvedValue(fail("Gagal"));
    const store = makeStore();
    await store.dispatch(thunk(arg));
    expect((store.getState().users as any)[flag]).toBe(false);
    expect(toolsHelper.showErrorDialog).toHaveBeenCalledWith("Gagal");
  });

  it("ditolak", async () => {
    mock(api).mockRejectedValue(new Error("jaringan"));
    const store = makeStore();
    await store.dispatch(thunk(arg));
    expect((store.getState().users as any)[flag]).toBe(false);
  });
});