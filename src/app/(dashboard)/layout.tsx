import type { ReactNode } from "react";
import PostLayout from "@/features/posts/layouts/PostLayout";

export default function Layout({ children }: { children: ReactNode }) {
  return <PostLayout>{children}</PostLayout>;
}