import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach, vi } from "vitest";

// next/link tidak butuh router saat diuji: cukup render sebagai <a>
vi.mock("next/link", async () => {
  const React = await import("react");
  return {
    default: ({ href, children, ...rest }: Record<string, unknown>) =>
      React.createElement("a", { ...rest, href }, children as never),
  };
});

afterEach(() => {
  cleanup();
});