import { Suspense } from "react";
import HomePage from "@/features/posts/pages/HomePage";

export default function Page() {
  return (
    <Suspense fallback={null}>
      <HomePage />
    </Suspense>
  );
}