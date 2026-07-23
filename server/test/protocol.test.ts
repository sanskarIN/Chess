import assert from "node:assert/strict";
import test from "node:test";

import {
  parseClientMessage,
  ProtocolError,
  PROTOCOL_VERSION,
} from "../src/protocol.js";

test("accepts four and six digit room messages", () => {
  const create = parseClientMessage(
    JSON.stringify({
      protocolVersion: PROTOCOL_VERSION,
      type: "create_room",
      requestId: "create",
      playerName: "Ada",
      preferredSide: "random",
      codeLength: 6,
    }),
  );
  const join = parseClientMessage(
    JSON.stringify({
      protocolVersion: PROTOCOL_VERSION,
      type: "join_room",
      requestId: "join",
      playerName: "Grace",
      teamCode: "0042",
    }),
  );

  assert.equal(create.type, "create_room");
  assert.equal(create.codeLength, 6);
  assert.equal(join.type, "join_room");
  assert.equal(join.teamCode, "0042");
});

test("rejects protocol mismatch, malformed names, and malformed moves", () => {
  assert.throws(
    () =>
      parseClientMessage(
        JSON.stringify({
          protocolVersion: 99,
          type: "ping",
          requestId: "bad-version",
        }),
      ),
    (error: unknown) =>
      error instanceof ProtocolError && error.code === "protocol_mismatch",
  );
  assert.throws(
    () =>
      parseClientMessage(
        JSON.stringify({
          protocolVersion: PROTOCOL_VERSION,
          type: "create_room",
          requestId: "bad-name",
          playerName: "Ada\nInjected",
          preferredSide: "white",
          codeLength: 4,
        }),
      ),
    ProtocolError,
  );
  assert.throws(
    () =>
      parseClientMessage(
        JSON.stringify({
          protocolVersion: PROTOCOL_VERSION,
          type: "move",
          requestId: "bad-move",
          teamCode: "123456",
          reconnectToken: "a".repeat(64),
          ply: 1,
          uci: "e2e9",
          previousStateHash: "0".repeat(64),
        }),
      ),
    ProtocolError,
  );
});
