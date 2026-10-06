import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";
import { defineConfig, type UserConfig } from "vitest/config";

export default defineConfig({
  // @vitejs/plugin-react is typed against the top-level Vite, while vitest ships
  // its own copy; cast so the two Plugin types don't clash during type checking.
  plugins: [react()] as UserConfig["plugins"],
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/*.test.{ts,tsx}"],
    coverage: {
      provider: "v8",
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/app/**", "src/types/**", "src/test/**", "src/**/*.test.{ts,tsx}", "src/**/*.d.ts"],
      reporter: ["text", "html"],
      thresholds: { statements: 100, branches: 100, functions: 100, lines: 100 },
    },
  },
});