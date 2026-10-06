import { describe, expect, it } from "vitest";
import store from "./store";

describe("store", () => {
  it("mendaftarkan slice auth, users, dan posts", () => {
    expect(Object.keys(store.getState()).sort()).toEqual(["auth", "posts", "users"]);
  });
});