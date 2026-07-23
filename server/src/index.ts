import { loadConfig } from "./config.js";
import { JsonRelayLogger } from "./logger.js";
import { createRelayServer } from "./server.js";

const logger = new JsonRelayLogger();

try {
  const relay = createRelayServer(loadConfig(), logger);
  await relay.start();

  let shuttingDown = false;
  const shutdown = async (signal: string): Promise<void> => {
    if (shuttingDown) {
      return;
    }
    shuttingDown = true;
    logger.info("shutdown_requested", { signal });
    try {
      await relay.stop();
      process.exitCode = 0;
    } catch (error) {
      logger.error("shutdown_failed", {
        errorType: error instanceof Error ? error.name : "unknown",
      });
      process.exitCode = 1;
    }
  };

  process.once("SIGINT", () => void shutdown("SIGINT"));
  process.once("SIGTERM", () => void shutdown("SIGTERM"));
} catch (error) {
  logger.error("relay_start_failed", {
    errorType: error instanceof Error ? error.name : "unknown",
  });
  process.exitCode = 1;
}
