import assert from "node:assert/strict";
import test from "node:test";

import {
  parseClientMessage,
  ProtocolError,
  PROTOCOL_VERSION,
  type ServerMessage,
} from "../src/protocol.js";
import {
  type ClientPeer,
  RoomManager,
} from "../src/room_manager.js";

const hostToken = "a".repeat(64);
const joinToken = "b".repeat(64);

test("creates both code lengths and runs an authoritative legal game", () => {
  let nextToken = 0;
  const manager = new RoomManager({
    roomTtlMs: 60_000,
    reconnectGraceMs: 5_000,
    generateCode: (length) => (length === 4 ? "0042" : "123456"),
    generateToken: () => (nextToken++ === 0 ? hostToken : joinToken),
  });
  const host = new FakePeer("host");
  const guest = new FakePeer("guest");

  manager.handle(
    host,
    message({
      type: "create_room",
      requestId: "create",
      playerName: "Ada",
      preferredSide: "white",
      codeLength: 6,
    }),
  );
  assert.equal(host.last("room_created").teamCode, "123456");

  manager.handle(
    guest,
    message({
      type: "join_room",
      requestId: "join",
      playerName: "Grace",
      teamCode: "123456",
    }),
  );
  assert.equal(guest.last("room_joined").assignedColor, "black");

  manager.handle(
    host,
    message({
      type: "ready",
      requestId: "ready-host",
      teamCode: "123456",
      reconnectToken: hostToken,
    }),
  );
  manager.handle(
    guest,
    message({
      type: "ready",
      requestId: "ready-guest",
      teamCode: "123456",
      reconnectToken: joinToken,
    }),
  );
  const started = host.last("game_started");
  const initialHash = String(started.stateHash);
  assert.deepEqual(started.moves, []);

  assert.throws(
    () =>
      manager.handle(
        guest,
        message({
          type: "move",
          requestId: "out-of-turn",
          teamCode: "123456",
          reconnectToken: joinToken,
          ply: 1,
          uci: "e7e5",
          previousStateHash: initialHash,
        }),
      ),
    (error: unknown) =>
      error instanceof ProtocolError && error.code === "illegal_move",
  );

  manager.handle(
    host,
    message({
      type: "move",
      requestId: "move-white",
      teamCode: "123456",
      reconnectToken: hostToken,
      ply: 1,
      uci: "e2e4",
      previousStateHash: initialHash,
    }),
  );
  const afterWhite = guest.last("state");
  assert.deepEqual(afterWhite.moves, ["e2e4"]);

  assert.throws(
    () =>
      manager.handle(
        guest,
        message({
          type: "move",
          requestId: "illegal",
          teamCode: "123456",
          reconnectToken: joinToken,
          ply: 2,
          uci: "e7e4",
          previousStateHash: String(afterWhite.stateHash),
        }),
      ),
    (error: unknown) =>
      error instanceof ProtocolError && error.code === "illegal_move",
  );

  manager.handle(
    guest,
    message({
      type: "move",
      requestId: "move-black",
      teamCode: "123456",
      reconnectToken: joinToken,
      ply: 2,
      uci: "e7e5",
      previousStateHash: String(afterWhite.stateHash),
    }),
  );
  assert.deepEqual(host.last("state").moves, ["e2e4", "e7e5"]);

  const fourManager = new RoomManager({
    roomTtlMs: 60_000,
    reconnectGraceMs: 5_000,
    generateCode: () => "0042",
    generateToken: () => hostToken,
  });
  const fourHost = new FakePeer("four-host");
  fourManager.handle(
    fourHost,
    message({
      type: "create_room",
      requestId: "create-four",
      playerName: "Ada",
      preferredSide: "black",
      codeLength: 4,
    }),
  );
  assert.equal(fourHost.last("room_created").teamCode, "0042");
  assert.equal(fourHost.last("room_created").assignedColor, "black");
});

test("reconnects sessions and expires fully disconnected rooms", () => {
  let now = 1_000;
  let tokenIndex = 0;
  const manager = new RoomManager({
    roomTtlMs: 60_000,
    reconnectGraceMs: 1_000,
    now: () => now,
    generateCode: () => "123456",
    generateToken: () => (tokenIndex++ === 0 ? hostToken : joinToken),
  });
  const host = new FakePeer("host");
  manager.handle(
    host,
    message({
      type: "create_room",
      requestId: "create",
      playerName: "Ada",
      preferredSide: "white",
      codeLength: 6,
    }),
  );
  manager.disconnect(host);

  const replacement = new FakePeer("replacement");
  manager.handle(
    replacement,
    message({
      type: "reconnect",
      requestId: "reconnect",
      teamCode: "123456",
      reconnectToken: hostToken,
      lastStateHash: "0".repeat(64),
    }),
  );
  assert.equal(replacement.last("reconnected").assignedColor, "white");

  manager.disconnect(replacement);
  now += 1_001;
  assert.equal(manager.sweep(), 1);
  assert.equal(manager.activeRoomCount, 0);

  const late = new FakePeer("late");
  assert.throws(
    () =>
      manager.handle(
        late,
        message({
          type: "join_room",
          requestId: "late-join",
          playerName: "Grace",
          teamCode: "123456",
        }),
      ),
    (error: unknown) =>
      error instanceof ProtocolError && error.code === "expired_code",
  );
});

function message(fields: Record<string, unknown>) {
  return parseClientMessage(
    JSON.stringify({
      protocolVersion: PROTOCOL_VERSION,
      ...fields,
    }),
  );
}

class FakePeer implements ClientPeer {
  public readonly messages: ServerMessage[] = [];
  public readonly closes: Array<{ code: number; reason: string }> = [];

  public constructor(public readonly id: string) {}

  public send(messageValue: ServerMessage): void {
    this.messages.push(messageValue);
  }

  public close(code: number, reason: string): void {
    this.closes.push({ code, reason });
  }

  public last(type: string): ServerMessage {
    const found = this.messages.findLast(
      (messageValue) => messageValue.type === type,
    );
    assert.ok(found, `Expected message type ${type}.`);
    return found;
  }
}
