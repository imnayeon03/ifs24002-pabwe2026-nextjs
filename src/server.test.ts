import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => {
  const handle = vi.fn();
  const listen = vi.fn((_port: number, callback: () => void) => callback());
  return {
    handle,
    listen,
    createServer: vi.fn((_handler: (req: unknown, res: unknown) => void) => ({ listen })),
    nextFactory: vi.fn((_options: { dev: boolean }) => ({
      prepare: () => Promise.resolve(),
      getRequestHandler: () => handle,
    })),
  };
});

vi.mock("node:http", () => ({
  createServer: mocks.createServer,
  default: { createServer: mocks.createServer },
}));
vi.mock("next", () => ({ default: mocks.nextFactory }));

const originalArgv = [...process.argv];
const originalPort = process.env.APP_PORT;

beforeEach(() => {
  vi.clearAllMocks();
  vi.resetModules();
  vi.spyOn(console, "log").mockImplementation(() => {});
});

afterEach(() => {
  process.argv = [...originalArgv];
  if (originalPort === undefined) delete process.env.APP_PORT;
  else process.env.APP_PORT = originalPort;
  vi.restoreAllMocks();
});

describe("server", () => {
  it("berjalan dalam mode dev di port 3000 secara bawaan", async () => {
    process.argv = ["node", "server.ts"];
    delete process.env.APP_PORT;

    await import("./server");
    await vi.waitFor(() => expect(mocks.listen).toHaveBeenCalled());

    expect(mocks.nextFactory).toHaveBeenCalledWith({ dev: true });
    expect(mocks.listen.mock.calls[0][0]).toBe(3000);
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining("http://localhost:3000 (dev)"));
  });

  it("meneruskan permintaan ke handler Next", async () => {
    process.argv = ["node", "server.ts"];

    await import("./server");
    await vi.waitFor(() => expect(mocks.createServer).toHaveBeenCalled());

    const handler = mocks.createServer.mock.calls[0][0];
    const req = { url: "/" };
    const res = {};
    handler(req, res);
    expect(mocks.handle).toHaveBeenCalledWith(req, res);
  });

  it("berjalan dalam mode production dengan port dari APP_PORT", async () => {
    process.argv = ["node", "server.ts", "--prod"];
    process.env.APP_PORT = "4000";

    await import("./server");
    await vi.waitFor(() => expect(mocks.listen).toHaveBeenCalled());

    expect(mocks.nextFactory).toHaveBeenCalledWith({ dev: false });
    expect(mocks.listen.mock.calls[0][0]).toBe(4000);
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining("(production)"));
  });
});