import { randomUUID } from "node:crypto";
import { createServer, type Server as HttpServer } from "node:http";

import {
  WebSocket,
  WebSocketServer,
  type RawData,
} from "ws";

import type { RelayConfig } from "./config.js";
import { JsonRelayLogger, type RelayLogger } from "./logger.js";
import {
  parseClientMessage,
  ProtocolError,
  type ServerMessage,
  serverMessage,
} from "./protocol.js";
import { SlidingWindowRateLimiter } from "./rate_limiter.js";
import { type ClientPeer, RoomManager } from "./room_manager.js";

export interface RelayServer {
  readonly httpServer: HttpServer;
  readonly roomManager: RoomManager;
  start(): Promise<number>;
  stop(): Promise<void>;
}

export function createRelayServer(
  config: RelayConfig,
  logger: RelayLogger = new JsonRelayLogger(),
): RelayServer {
  const startedAt = Date.now();
  const roomManager = new RoomManager({
    roomTtlMs: config.roomTtlMs,
    reconnectGraceMs: config.reconnectGraceMs,
  });
  const webSocketServer = new WebSocketServer({
    noServer: true,
    maxPayload: 16 * 1024,
    perMessageDeflate: false,
  });
  const peers = new Set<WebSocketPeer>();
  const httpServer = createServer((request, response) => {
    if (request.method === "GET" && request.url === "/health") {
      response.writeHead(200, {
        "content-type": "application/json; charset=utf-8",
        "cache-control": "no-store",
      });
      response.end(
        JSON.stringify({
          status: "ok",
          protocolVersion: 1,
          activeRooms: roomManager.activeRoomCount,
          uptimeSeconds: Math.floor((Date.now() - startedAt) / 1_000),
        }),
      );
      return;
    }
    response.writeHead(404, {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    });
    response.end(JSON.stringify({ error: "not_found" }));
  });

  httpServer.on("upgrade", (request, socket, head) => {
    if (request.url !== "/ws") {
      socket.write("HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n");
      socket.destroy();
      return;
    }
    const origin = request.headers.origin;
    if (
      origin !== undefined &&
      config.allowedOrigins.size > 0 &&
      !config.allowedOrigins.has(origin)
    ) {
      socket.write("HTTP/1.1 403 Forbidden\r\nConnection: close\r\n\r\n");
      socket.destroy();
      return;
    }
    webSocketServer.handleUpgrade(request, socket, head, (webSocket) => {
      webSocketServer.emit("connection", webSocket, request);
    });
  });

  webSocketServer.on("connection", (socket) => {
    const peer = new WebSocketPeer(
      randomUUID(),
      socket,
      new SlidingWindowRateLimiter(
        config.rateLimitMessages,
        config.rateLimitWindowMs,
      ),
      roomManager,
      logger,
    );
    peers.add(peer);
    peer.done.finally(() => peers.delete(peer)).catch(() => undefined);
    logger.info("connection_opened", { connections: peers.size });
  });

  const sweepTimer = setInterval(
    () => {
      const removed = roomManager.sweep();
      if (removed > 0) {
        logger.info("rooms_expired", {
          count: removed,
          activeRooms: roomManager.activeRoomCount,
        });
      }
    },
    Math.min(config.reconnectGraceMs, 10_000),
  );
  sweepTimer.unref();

  let stopping = false;
  return {
    httpServer,
    roomManager,
    async start(): Promise<number> {
      await new Promise<void>((resolve, reject) => {
        const onError = (error: Error): void => reject(error);
        httpServer.once("error", onError);
        httpServer.listen(config.port, config.host, () => {
          httpServer.off("error", onError);
          resolve();
        });
      });
      const address = httpServer.address();
      if (address === null || typeof address === "string") {
        throw new Error("Relay did not bind to a TCP port.");
      }
      logger.info("relay_started", {
        port: address.port,
        protocolVersion: 1,
      });
      return address.port;
    },
    async stop(): Promise<void> {
      if (stopping) {
        return;
      }
      stopping = true;
      clearInterval(sweepTimer);
      roomManager.closeAll();
      for (const peer of peers) {
        peer.close(1012, "relay shutting down");
      }
      await new Promise<void>((resolve) => {
        webSocketServer.close(() => resolve());
        if (webSocketServer.clients.size === 0) {
          resolve();
        }
      });
      await new Promise<void>((resolve, reject) => {
        httpServer.close((error) => {
          if (error === undefined) {
            resolve();
          } else {
            reject(error);
          }
        });
      });
      logger.info("relay_stopped");
    },
  };
}

class WebSocketPeer implements ClientPeer {
  public readonly done: Promise<void>;
  private readonly resolveDone: () => void;
  private closed = false;

  public constructor(
    public readonly id: string,
    private readonly socket: WebSocket,
    private readonly limiter: SlidingWindowRateLimiter,
    private readonly rooms: RoomManager,
    private readonly logger: RelayLogger,
  ) {
    let resolveDone = (): void => undefined;
    this.done = new Promise<void>((resolve) => {
      resolveDone = resolve;
    });
    this.resolveDone = resolveDone;
    socket.on("message", (data, isBinary) => this.onMessage(data, isBinary));
    socket.once("close", () => this.onClose());
    socket.once("error", () => this.onClose());
  }

  public send(message: ServerMessage): void {
    if (this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify(message));
    }
  }

  public close(code: number, reason: string): void {
    if (this.socket.readyState === WebSocket.OPEN) {
      this.socket.close(code, reason);
    }
  }

  private onMessage(data: RawData, isBinary: boolean): void {
    const payload = rawDataBuffer(data);
    if (isBinary || payload.byteLength > 16 * 1024) {
      this.sendError("invalid_message", "Only small JSON text messages work.");
      this.close(1003, "invalid payload");
      return;
    }
    if (!this.limiter.allow()) {
      this.sendError("rate_limited", "Too many messages; retry later.");
      return;
    }
    try {
      const message = parseClientMessage(payload.toString("utf8"));
      this.rooms.handle(this, message);
    } catch (error) {
      if (error instanceof ProtocolError) {
        this.send(
          serverMessage("error", error.requestId, {
            code: error.code,
            message: error.message,
          }),
        );
        this.logger.warn("message_rejected", { code: error.code });
        return;
      }
      this.sendError("internal_error", "The relay could not process the message.");
      this.logger.error("message_failure", {
        errorType: error instanceof Error ? error.name : "unknown",
      });
    }
  }

  private sendError(code: string, message: string): void {
    this.send(serverMessage("error", "unknown", { code, message }));
  }

  private onClose(): void {
    if (this.closed) {
      return;
    }
    this.closed = true;
    this.rooms.disconnect(this);
    this.logger.info("connection_closed");
    this.resolveDone();
  }
}

function rawDataBuffer(data: RawData): Buffer {
  if (Array.isArray(data)) {
    return Buffer.concat(data);
  }
  if (data instanceof ArrayBuffer) {
    return Buffer.from(data);
  }
  return Buffer.from(data);
}
