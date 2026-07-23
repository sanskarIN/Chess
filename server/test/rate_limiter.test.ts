import assert from "node:assert/strict";
import test from "node:test";

import { SlidingWindowRateLimiter } from "../src/rate_limiter.js";

test("rate limiter releases capacity after its monotonic window", () => {
  let now = 100;
  const limiter = new SlidingWindowRateLimiter(2, 1_000, () => now);

  assert.equal(limiter.allow(), true);
  assert.equal(limiter.allow(), true);
  assert.equal(limiter.allow(), false);
  now += 1_001;
  assert.equal(limiter.allow(), true);
});
