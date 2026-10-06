import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { useAppSelector } from "@/hooks/redux";
import Providers from "./Providers";

function Probe() {
  const isAuthLogin = useAppSelector((state) => state.auth.isAuthLogin);
  return <p>login: {String(isAuthLogin)}</p>;
}

describe("Providers", () => {
  it("menyediakan store Redux ke komponen anak", () => {
    render(
      <Providers>
        <Probe />
      </Providers>,
    );
    expect(screen.getByText("login: false")).toBeInTheDocument();
  });
});