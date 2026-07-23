import { randomBytes, randomInt } from "node:crypto";

import { Chess } from "chess.js";

import {
  type ClientMessage,
  type Color,
  ProtocolError,
  type ServerMessage,
  serverMessage,
} from "./protocol.js";
import { stateHash } from "./state_hash.js";

export interface ClientPeer {
  readonly id: string;
  send(message: ServerMessage): void;
  close(code: number, reason: string): void;
}

interface RoomPlayer {
  readonly name: string;
  readonly color: Color;
  readonly reconnectToken: string;
  peer: ClientPeer | null;
  ready: boolean;
  disconnectedAt: number | null;
}

interface Room {
  readonly code: string;
  readonly createdAt: number;
  readonly expiresAt: number;
  readonly players: Map<Color, RoomPlayer>;
  readonly chess: Chess;
  readonly moves: string[];
  started: boolean;
  hash: string;
}

export interface RoomManagerOptions {
  roomTtlMs: number;
  reconnectGraceMs: number;
  now?: () => number;
  generateCode?: (length: 4 | 6) => string;
  generateToken?: () => string;
}

export class RoomManager {
  private readonly rooms = new Map<string, Room>();
  private readonly bindings = new Map<
    string,
    { roomCode: string; color: Color }
  >();
  private readonly expiredCodes = new Map<string, number>();
  private readonly now: () => number;
  private readonly generateCode: (length: 4 | 6) => string;
  private readonly generateToken: () => string;

  public constructor(private readonly options: RoomManagerOptions) {
    this.now = options.now ?? Date.now;
    this.generateCode =
      options.generateCode ??
      ((length) =>
        randomInt(0, 10 ** length).toString().padStart(length, "0"));
    this.generateToken =
      options.generateToken ?? (() => randomBytes(32).toString("hex"));
  }

  public get activeRoomCount(): number {
    return this.rooms.size;
  }

  public handle(peer: ClientPeer, message: ClientMessage): void {
    this.sweep();
    switch (message.type) {
      case "create_room":
        this.create(peer, message);
        break;
      case "join_room":
        this.join(peer, message);
        break;
      case "ready":
        this.ready(peer, message);
        break;
      case "move":
        this.move(peer, message);
        break;
      case "reconnect":
        this.reconnect(peer, message);
        break;
      case "ping":
        peer.send(serverMessage("pong", message.requestId));
        break;
    }
  }

  public disconnect(peer: ClientPeer): void {
    const binding = this.bindings.get(peer.id);
    if (binding === undefined) {
      return;
    }
    this.bindings.delete(peer.id);
    const room = this.rooms.get(binding.roomCode);
    const player = room?.players.get(binding.color);
    if (room === undefined || player?.peer?.id !== peer.id) {
      return;
    }
    player.peer = null;
    player.ready = false;
    player.disconnectedAt = this.now();
    this.broadcastRoomUpdate(room, "disconnect");
  }

  public sweep(): number {
    const now = this.now();
    let deleted = 0;
    for (const [code, room] of this.rooms) {
      const connected = [...room.players.values()].some(
        (player) => player.peer !== null,
      );
      const latestDisconnect = Math.max(
        ...[...room.players.values()].map(
          (player) => player.disconnectedAt ?? room.createdAt,
        ),
      );
      const disconnectedExpired =
        !connected &&
        now - latestDisconnect >= this.options.reconnectGraceMs;
      if (now >= room.expiresAt || disconnectedExpired) {
        this.deleteRoom(code, room, now);
        deleted++;
      }
    }
    for (const [code, until] of this.expiredCodes) {
      if (until <= now) {
        this.expiredCodes.delete(code);
      }
    }
    return deleted;
  }

  public closeAll(): void {
    for (const room of this.rooms.values()) {
      for (const player of room.players.values()) {
        player.peer?.close(1012, "relay shutting down");
      }
    }
    this.rooms.clear();
    this.bindings.clear();
  }

  private create(
    peer: ClientPeer,
    message: Extract<ClientMessage, { type: "create_room" }>,
  ): void {
    this.ensureUnbound(peer, message.requestId);
    let code = "";
    for (let attempt = 0; attempt < 100; attempt++) {
      const candidate = this.generateCode(message.codeLength);
      if (!this.rooms.has(candidate)) {
        code = candidate;
        break;
      }
    }
    if (code.length === 0) {
      throw new ProtocolError(
        "room_space_exhausted",
        "No team code is currently available.",
        message.requestId,
      );
    }
    const hostColor = this.resolveSide(message.preferredSide);
    const createdAt = this.now();
    const chess = new Chess();
    const room: Room = {
      code,
      createdAt,
      expiresAt: createdAt + this.options.roomTtlMs,
      players: new Map(),
      chess,
      moves: [],
      started: false,
      hash: stateHash(chess.fen(), []),
    };
    const player: RoomPlayer = {
      name: message.playerName,
      color: hostColor,
      reconnectToken: this.generateToken(),
      peer,
      ready: false,
      disconnectedAt: null,
    };
    room.players.set(hostColor, player);
    this.rooms.set(code, room);
    this.bindings.set(peer.id, { roomCode: code, color: hostColor });
    this.sendIdentity(peer, room, player, "room_created", message.requestId);
    this.broadcastRoomUpdate(room, message.requestId);
  }

  private join(
    peer: ClientPeer,
    message: Extract<ClientMessage, { type: "join_room" }>,
  ): void {
    this.ensureUnbound(peer, message.requestId);
    const room = this.lookupRoom(message.teamCode, message.requestId);
    if (room.players.size >= 2) {
      throw new ProtocolError(
        "room_full",
        "That room already has two players.",
        message.requestId,
      );
    }
    const host = [...room.players.values()][0];
    if (host === undefined) {
      throw new ProtocolError(
        "invalid_code",
        "That team code does not exist.",
        message.requestId,
      );
    }
    const color = opposite(host.color);
    const player: RoomPlayer = {
      name: message.playerName,
      color,
      reconnectToken: this.generateToken(),
      peer,
      ready: false,
      disconnectedAt: null,
    };
    room.players.set(color, player);
    this.bindings.set(peer.id, { roomCode: room.code, color });
    this.sendIdentity(peer, room, player, "room_joined", message.requestId);
    this.broadcastRoomUpdate(room, message.requestId);
  }

  private ready(
    peer: ClientPeer,
    message: Extract<ClientMessage, { type: "ready" }>,
  ): void {
    const { room, player } = this.authorize(
      peer,
      message.teamCode,
      message.reconnectToken,
      message.requestId,
    );
    player.ready = true;
    this.broadcastRoomUpdate(room, message.requestId);
    if (
      room.players.size === 2 &&
      [...room.players.values()].every(
        (candidate) => candidate.ready && candidate.peer !== null,
      )
    ) {
      room.started = true;
      this.broadcastState(room, "game_started", message.requestId);
    }
  }

  private move(
    peer: ClientPeer,
    message: Extract<ClientMessage, { type: "move" }>,
  ): void {
    const { room, player } = this.authorize(
      peer,
      message.teamCode,
      message.reconnectToken,
      message.requestId,
    );
    if (!room.started) {
      throw new ProtocolError(
        "invalid_message",
        "The match has not started.",
        message.requestId,
      );
    }
    if (message.previousStateHash !== room.hash) {
      this.sendState(peer, room, "state", message.requestId);
      throw new ProtocolError(
        "state_hash_mismatch",
        "Client state is stale; authoritative state was sent.",
        message.requestId,
      );
    }
    if (message.ply !== room.moves.length + 1) {
      throw new ProtocolError(
        "state_hash_mismatch",
        "Move ply does not match the room state.",
        message.requestId,
      );
    }
    const expectedColor: Color = room.chess.turn() === "w" ? "white" : "black";
    if (player.color !== expectedColor) {
      throw new ProtocolError(
        "illegal_move",
        "It is not this player's turn.",
        message.requestId,
      );
    }
    const promotion = message.uci.length === 5 ? message.uci[4] : undefined;
    try {
      room.chess.move({
        from: message.uci.slice(0, 2),
        to: message.uci.slice(2, 4),
        ...(promotion === undefined ? {} : { promotion }),
      });
    } catch {
      throw new ProtocolError(
        "illegal_move",
        "The move is illegal in the authoritative position.",
        message.requestId,
      );
    }
    room.moves.push(message.uci);
    room.hash = stateHash(room.chess.fen(), room.moves);
    this.broadcastState(room, "state", message.requestId);
  }

  private reconnect(
    peer: ClientPeer,
    message: Extract<ClientMessage, { type: "reconnect" }>,
  ): void {
    this.ensureUnbound(peer, message.requestId);
    const room = this.lookupRoom(message.teamCode, message.requestId);
    const player = [...room.players.values()].find(
      (candidate) => candidate.reconnectToken === message.reconnectToken,
    );
    if (player === undefined) {
      throw new ProtocolError(
        "invalid_code",
        "Reconnect credentials are invalid.",
        message.requestId,
      );
    }
    if (player.peer !== null && player.peer.id !== peer.id) {
      this.bindings.delete(player.peer.id);
      player.peer.close(4001, "session replaced");
    }
    player.peer = peer;
    player.disconnectedAt = null;
    this.bindings.set(peer.id, { roomCode: room.code, color: player.color });
    this.sendIdentity(peer, room, player, "reconnected", message.requestId);
    this.broadcastRoomUpdate(room, message.requestId);
    if (room.started) {
      this.sendState(peer, room, "state", message.requestId);
    }
  }

  private authorize(
    peer: ClientPeer,
    teamCode: string,
    reconnectToken: string,
    requestId: string,
  ): { room: Room; player: RoomPlayer } {
    const binding = this.bindings.get(peer.id);
    if (binding?.roomCode !== teamCode) {
      throw new ProtocolError(
        "invalid_code",
        "This connection is not a member of that room.",
        requestId,
      );
    }
    const room = this.lookupRoom(teamCode, requestId);
    const player = room.players.get(binding.color);
    if (
      player === undefined ||
      player.peer?.id !== peer.id ||
      player.reconnectToken !== reconnectToken
    ) {
      throw new ProtocolError(
        "invalid_code",
        "Session credentials are invalid.",
        requestId,
      );
    }
    return { room, player };
  }

  private lookupRoom(code: string, requestId: string): Room {
    const room = this.rooms.get(code);
    if (room !== undefined && room.expiresAt <= this.now()) {
      this.deleteRoom(code, room, this.now());
    }
    const current = this.rooms.get(code);
    if (current !== undefined) {
      return current;
    }
    if (this.expiredCodes.has(code)) {
      throw new ProtocolError(
        "expired_code",
        "That team code has expired.",
        requestId,
      );
    }
    throw new ProtocolError(
      "invalid_code",
      "That team code does not exist.",
      requestId,
    );
  }

  private ensureUnbound(peer: ClientPeer, requestId: string): void {
    if (this.bindings.has(peer.id)) {
      throw new ProtocolError(
        "invalid_message",
        "This connection is already assigned to a room.",
        requestId,
      );
    }
  }

  private resolveSide(side: "white" | "black" | "random"): Color {
    if (side === "random") {
      return randomInt(0, 2) === 0 ? "white" : "black";
    }
    return side;
  }

  private sendIdentity(
    peer: ClientPeer,
    room: Room,
    player: RoomPlayer,
    type: "room_created" | "room_joined" | "reconnected",
    requestId: string,
  ): void {
    peer.send(
      serverMessage(type, requestId, {
        teamCode: room.code,
        assignedColor: player.color,
        reconnectToken: player.reconnectToken,
        expiresAt: new Date(room.expiresAt).toISOString(),
      }),
    );
  }

  private broadcastRoomUpdate(room: Room, requestId: string): void {
    const message = serverMessage("room_update", requestId, {
      expiresAt: new Date(room.expiresAt).toISOString(),
      players: this.playerPayload(room),
    });
    this.broadcast(room, message);
  }

  private broadcastState(
    room: Room,
    type: "game_started" | "state",
    requestId: string,
  ): void {
    const message = serverMessage(type, requestId, {
      fen: room.chess.fen(),
      moves: [...room.moves],
      stateHash: room.hash,
      players: this.playerPayload(room),
      gameOver: room.chess.isGameOver(),
    });
    this.broadcast(room, message);
  }

  private sendState(
    peer: ClientPeer,
    room: Room,
    type: "state",
    requestId: string,
  ): void {
    peer.send(
      serverMessage(type, requestId, {
        fen: room.chess.fen(),
        moves: [...room.moves],
        stateHash: room.hash,
        players: this.playerPayload(room),
        gameOver: room.chess.isGameOver(),
      }),
    );
  }

  private playerPayload(room: Room): ReadonlyArray<Record<string, unknown>> {
    return [...room.players.values()]
      .sort((left, right) => left.color.localeCompare(right.color))
      .map((player) => ({
        name: player.name,
        color: player.color,
        connected: player.peer !== null,
        ready: player.ready,
      }));
  }

  private broadcast(room: Room, message: ServerMessage): void {
    for (const player of room.players.values()) {
      player.peer?.send(message);
    }
  }

  private deleteRoom(code: string, room: Room, now: number): void {
    this.rooms.delete(code);
    this.expiredCodes.set(code, now + this.options.roomTtlMs);
    for (const player of room.players.values()) {
      if (player.peer !== null) {
        this.bindings.delete(player.peer.id);
        player.peer.close(4004, "room expired");
      }
    }
  }
}

function opposite(color: Color): Color {
  return color === "white" ? "black" : "white";
}
