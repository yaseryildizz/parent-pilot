import { buildApp } from "./app/build-app.js";
import { loadConfig } from "./config/config.js";

const config = loadConfig();
const app = buildApp({ config });

try {
  await app.listen({ host: config.host, port: config.port });
  console.log(`ParentPilot backend listening on http://${config.host}:${config.port}`);
  app.log.info(`ParentPilot backend listening on http://${config.host}:${config.port}`);
} catch (error) {
  app.log.error(error);
  console.error(error);
  process.exit(1);
}
