import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

import { stateHash } from "../src/state_hash.js";

test("matches shared Dart/Node protocol state fixtures", () => {
  const fixtures = JSON.parse(
    readFileSync("../protocol/friend_state_fixtures.json", "utf8"),
  ) as Array<{ fen: string; moves: string[]; stateHash: string }>;

  for (const fixture of fixtures) {
    assert.equal(
      stateHash(fixture.fen, fixture.moves),
      fixture.stateHash,
    );
  }
});
