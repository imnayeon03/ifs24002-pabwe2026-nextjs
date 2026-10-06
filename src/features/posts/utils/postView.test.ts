import { describe, expect, it } from "vitest";
import type { Post } from "@/types";
import { formatDate, toPostView } from "./postView";

const asPost = (value: unknown) => value as Post;

describe("formatDate", () => {
  it("mengembalikan string kosong untuk nilai kosong atau tidak valid", () => {
    expect(formatDate("")).toBe("");
    expect(formatDate("bukan-tanggal")).toBe("");
  });

  it("memformat tanggal valid", () => {
    expect(formatDate("2026-01-05T00:00:00Z")).toContain("2026");
  });
});

describe("toPostView", () => {
  it("memetakan postingan lengkap milik sendiri", () => {
    const view = toPostView(
      asPost({
        id: 1,
        user_id: 7,
        description: "Halo",
        cover: "c.png",
        created_at: "2026-01-05",
        total_likes: 3,
        total_comments: 2,
        author: { id: 7, name: "Budi", photo: "b.png" },
        likes: [{ user_id: 7 }],
        comments: [
          {
            id: 5,
            user_id: 7,
            comment: "Mantap",
            created_at: "2026-01-06",
            author: { id: 7, name: "Budi", photo: "b.png" },
          },
        ],
      }),
      7,
    );
    expect(view).toMatchObject({
      id: 1,
      description: "Halo",
      authorName: "Budi",
      totalLikes: 3,
      totalComments: 2,
      isMine: true,
      isLiked: true,
    });
    expect(view.comments[0]).toMatchObject({ id: 5, userId: 7, text: "Mantap", authorName: "Budi" });
  });

  it("memakai nilai bawaan untuk data minimal", () => {
    const view = toPostView(asPost({ id: 2 }));
    expect(view).toMatchObject({
      description: "",
      authorName: "Pengguna",
      createdAt: "",
      totalLikes: 0,
      totalComments: 0,
      isMine: false,
      isLiked: false,
      comments: [],
    });
  });

  it("mengenali pemilik lewat author.id dan komentar dengan field alternatif", () => {
    const view = toPostView(
      asPost({
        id: 3,
        author: { id: 9 },
        comments: [{ user: { id: 9, name: "Sari" } }, {}],
      }),
      9,
    );
    expect(view.isMine).toBe(true);
    expect(view.isLiked).toBe(false);
    expect(view.comments[0]).toMatchObject({ id: 0, userId: 9, text: "", authorName: "Sari", createdAt: "" });
    expect(view.comments[1]).toMatchObject({ id: 1, userId: undefined, authorName: "Pengguna" });
  });

  it("memakai field user bila author tidak ada dan membedakan pemilik lain", () => {
    const view = toPostView(asPost({ id: 4, user_id: 1, user: { name: "Ani" } }), 2);
    expect(view.authorName).toBe("Ani");
    expect(view.isMine).toBe(false);
  });
});