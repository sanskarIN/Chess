import assert from "node:assert/strict";
import test from "node:test";

import { WebSocket } from "ws";

import type { RelayConfig } from "../src/config.js";
import type { RelayLogger } from "../src/logger.js";
import { PROTOCOL_VERSION } from "../src/protocol.js";
import { createRelayServer } from "../src/server.js";

test("serves health, WebSocket protocol, and graceful shutdown", async () => {
  const config: RelayConfig = {
    host: "127.0.0.1",
    port: 0,
    roomTtlMs: 60_000,
    reconnectGraceMs: 1_000,
    rateLimitWindowMs: 10_000,
    rateLimitMessages: 2,
    allowedOrigins: new Set(),
  };
  const relay = createRelayServer(config, new SilentLogger());
  const port = await relay.start();

  const health = await fetch(`http://127.0.0.1:${port}/health`);
  assert.equal(health.status, 200);
  const healthBody = (await health.json()) as Record<string, unknown>;
  assert.equal(healthBody.status, "ok");
  assert.equal(healthBody.protocolVersion, 1);
  assert.equal(healthBody.activeRooms, 0);
  assert.equal(typeof healthBody.uptimeSeconds, "number");

  const socket = new WebSocket(`ws://127.0.0.1:${port}/ws`);
  await new Promise<void>((resolve, reject) => {
    socket.once("open", () => resolve());
    socket.once("error", reject);
  });
  const messages: Array<Record<string, unknown>> = [];
  socket.on("message", (data) => {
    messages.push(JSON.parse(data.toString()) as Record<string, unknown>);
  });
  const ping = (requestId: string): void => {
    socket.send(
      JSON.stringify({
        protocolVersion: PROTOCOL_VERSION,
        type: "ping",
        requestId,
      }),
    );
  };
  ping("one");
  ping("two");
  ping("three");
  await waitFor(() => messages.length >= 3);

  assert.equal(messages[0]?.type, "pong");
  assert.equal(messages[1]?.type, "pong");
  assert.equal(messages[2]?.type, "error");
  assert.equal(messages[2]?.code, "rate_limited");

  socket.close();
  await relay.stop();
  assert.equal(relay.httpServer.listening, false);
});

async function waitFor(predicate: () => boolean): Promise<void> {
  const deadline = Date.now() + 2_000;
  while (!predicate()) {
    if (Date.now() >= deadline) {
      throw new Error("Timed out waiting for relay response.");
    }
    await new Promise((resolve) => setTimeout(resolve, 5));
  }
}

class SilentLogger implements RelayLogger {
  public info(): void {}
  public warn(): void {}
  public error(): void {}
}
