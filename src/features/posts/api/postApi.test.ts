import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiFetch } from "@/helpers/apiHelper";
import * as api from "./postApi";

vi.mock("@/helpers/apiHelper", () => ({ apiFetch: vi.fn() }));

const fetchMock = vi.mocked(apiFetch);

beforeEach(() => {
  fetchMock.mockReset();
});

describe("postApi", () => {
  it("getPosts tanpa dan dengan filter milik sendiri", () => {
    api.getPosts();
    expect(fetchMock).toHaveBeenLastCalledWith("/posts", { query: { is_me: undefined } });
    api.getPosts(true);
    expect(fetchMock).toHaveBeenLastCalledWith("/posts", { query: { is_me: 1 } });
  });

  it("getPost", () => {
    api.getPost(3);
    expect(fetchMock).toHaveBeenCalledWith("/posts/3");
  });

  it("addPost", () => {
    api.addPost("Halo");
    expect(fetchMock).toHaveBeenCalledWith("/posts", { method: "POST", body: { description: "Halo" } });
  });

  it("changePost", () => {
    api.changePost(1, "Baru");
    expect(fetchMock).toHaveBeenCalledWith("/posts/1", { method: "PUT", body: { description: "Baru" } });
  });

  it("changePostCover mengirim FormData", () => {
    api.changePostCover(1, new File(["x"], "a.png"));
    const [path, options] = fetchMock.mock.calls[0] as [string, { method: string; body: FormData }];
    expect(path).toBe("/posts/1/cover");
    expect(options.method).toBe("POST");
    expect((options.body.get("cover") as File).name).toBe("a.png");
  });

  it("deletePost", () => {
    api.deletePost(1);
    expect(fetchMock).toHaveBeenCalledWith("/posts/1", { method: "DELETE" });
  });

  it("likePost", () => {
    api.likePost(1, 1);
    expect(fetchMock).toHaveBeenCalledWith("/posts/1/likes", { method: "POST", body: { like: 1 } });
  });

  it("addComment", () => {
    api.addComment(1, "Hai");
    expect(fetchMock).toHaveBeenCalledWith("/posts/1/comments", { method: "POST", body: { comment: "Hai" } });
  });

  it("deleteComment", () => {
    api.deleteComment(1);
    expect(fetchMock).toHaveBeenCalledWith("/posts/1/comments", { method: "DELETE" });
  });

  it("deleteAllPosts", () => {
    api.deleteAllPosts();
    expect(fetchMock).toHaveBeenCalledWith("/posts", { method: "DELETE" });
  });
});