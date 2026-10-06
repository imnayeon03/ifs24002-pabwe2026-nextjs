import { createServer } from "node:http";
import next from "next";

const dev = !process.argv.includes("--prod");
const port = Number(process.env.APP_PORT ?? 3000);

const app = next({ dev });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  createServer((req, res) => handle(req, res)).listen(port, () => {
    console.log(`> Server siap di http://localhost:${port} (${dev ? "dev" : "production"})`);
  });
});