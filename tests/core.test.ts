// Contract tests for src/core.ts — the save/scoring/collision rules.
// These lock the MECHANICS. If a change breaks these, the change is
// wrong (or the spec changed and tests must be updated deliberately).
import { test } from "node:test";
import assert from "node:assert/strict";
import * as core from "../src/core";

test("completeEventPoint awards exactly 100 once per npc:phase", () => {
  let s = core.fresh();
  s = core.completeEventPoint(s, "mae", 1);
  assert.equal(s.score, 100);
  assert.equal(s.streak, 1);
  assert.equal(s.sessionEvents, 1);
  assert.deepEqual(s.completedEventPoints, ["mae:1"]);

  // Completing the same point again is a no-op
  const again = core.completeEventPoint(s, "mae", 1);
  assert.deepEqual(again, s);

  // A different phase counts separately
  s = core.completeEventPoint(s, "mae", 2);
  assert.equal(s.score, 200);
  assert.equal(s.streak, 2);
});

test("getCurrentPhase returns next incomplete phase, 5 when all done", () => {
  let s = core.fresh();
  assert.equal(core.getCurrentPhase(s, "mae"), 1);
  s = core.completeEventPoint(s, "mae", 1);
  assert.equal(core.getCurrentPhase(s, "mae"), 2);
  s = core.completeEventPoint(s, "mae", 2);
  s = core.completeEventPoint(s, "mae", 3);
  s = core.completeEventPoint(s, "mae", 4);
  assert.equal(core.getCurrentPhase(s, "mae"), 5);
});

test("errors never deduct score/streak; 3rd error on a point costs a life", () => {
  let s = core.completeEventPoint(core.fresh(), "mae", 1);
  const scoreBefore = s.score;
  const streakBefore = s.streak;

  s = core.recordError(s, "chester:1");
  s = core.recordError(s, "chester:1");
  assert.equal(s.lives, 3); // 2 errors: no life lost
  s = core.recordError(s, "chester:1");
  assert.equal(s.lives, 2); // 3rd error: life lost

  assert.equal(s.score, scoreBefore); // progress preserved
  assert.equal(s.streak, streakBefore);

  // Errors on DIFFERENT points don't share the counter
  s = core.recordError(s, "lily:1");
  s = core.recordError(s, "lily:1");
  assert.equal(s.lives, 2);
});

test("session ends at 5 events; game over at 0 lives; resetSession restores", () => {
  let s = core.fresh();
  assert.equal(core.sessionDone(s), false);
  assert.equal(core.gameOver(s), false);

  for (let i = 1; i <= 5; i++) s = core.completeEventPoint(s, `npc${i}`, 1);
  assert.equal(core.sessionDone(s), true);

  s = { ...s, lives: 0 };
  assert.equal(core.gameOver(s), true);

  const r = core.resetSession(s);
  assert.equal(r.lives, 3);
  assert.equal(r.sessionEvents, 0);
  assert.deepEqual(r.errors, {});
  assert.equal(r.score, s.score); // permanent progress survives reset
  assert.deepEqual(r.completedEventPoints, s.completedEventPoints);
});

test("versioned saves round-trip; malformed/unsupported saves recover safely", () => {
  let s = core.completeEventPoint(core.fresh(), "mae", 1);
  s = { ...s, muted: true };
  assert.deepEqual(core.restore(core.serialize(s)), s);

  for (const raw of ["{", "null", "{}", '{"version":2}', null]) {
    assert.deepEqual(core.restore(raw as string | null), core.fresh());
  }

  // Partial/corrupt v1 save: valid fields kept, invalid ones defaulted
  const partial = core.restore('{"version":1,"score":300,"lives":-5}');
  assert.equal(partial.score, 300);
  assert.equal(partial.lives, 3); // negative lives rejected
});

test("collision: bounds and walkableMap are both enforced", () => {
  // Minimal 40×30 map: everything blocked except (5,5) and (6,5)
  const map: boolean[][] = Array.from({ length: 30 }, () =>
    Array.from({ length: 40 }, () => false)
  );
  map[5][5] = true;
  map[5][6] = true;

  assert.equal(core.canMoveTo({ x: 5, y: 5 }, map), true);
  assert.equal(core.canMoveTo({ x: 6, y: 5 }, map), true);
  assert.equal(core.canMoveTo({ x: 7, y: 5 }, map), false); // blocked tile
  assert.equal(core.canMoveTo({ x: -1, y: 5 }, map), false); // out of bounds
  assert.equal(core.canMoveTo({ x: 40, y: 5 }, map), false);
  assert.equal(core.canMoveTo({ x: 5, y: 30 }, map), false);
});
