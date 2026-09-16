import { test } from "node:test";
import assert from "node:assert/strict";
import * as core from "../src/core";
test("five gated quests award exactly 100 each once; mistakes preserve progress", () => {
  assert.equal(typeof core.complete, "function");
  let s = core.fresh();
  assert.equal(core.available(s, "Chester"), false);
  assert.deepEqual(core.complete(s, "q2", 3), s);
  assert.deepEqual(core.complete(s, "q1", 2), s);
  for (const [id, count] of [
    ["q1", 3],
    ["q2", 4],
    ["q3", 2],
    ["q4", 5],
    ["q5", 6],
  ] as const) {
    s = core.complete(s, id, count);
    assert.deepEqual(core.complete(s, id, count), s);
  }
  assert.equal(s.score, 500);
  assert.equal(s.streak, 5);
  assert.equal(s.completed.length, 5);
  assert.equal(s.upgrade, 3);
  assert.equal(core.sessionDone(s), true);
});
test("versioned saves round-trip and malformed or unsupported saves recover safely", () => {
  assert.equal(typeof core.restore, "function");
  const s = { ...core.complete(core.fresh(), "q1", 3), muted: true };
  assert.deepEqual(core.restore(core.serialize(s)), s);
  for (const raw of [
    "{",
    "null",
    "{}",
    '{"version":2}',
    '{"version":1,"completed":["q5"]}',
    '{"version":1,"completed":["q1","q1"]}',
  ])
    assert.deepEqual(core.restore(raw), core.fresh());
  assert.deepEqual(
    core.restore(JSON.stringify({ ...s, score: 9999, upgrade: 99 })),
    s,
  );
});
test("walk through clear tiles but not buildings, NPCs or world edges", () => {
  assert.equal(typeof core.move, "function");
  assert.deepEqual(core.move({ x: 9, y: 10 }, 1, 0), { x: 10, y: 10 });
  assert.deepEqual(core.move({ x: 0, y: 10 }, -1, 0), { x: 0, y: 10 });
  assert.deepEqual(core.move({ x: 3, y: 5 }, 0, -1), { x: 3, y: 5 });
  assert.deepEqual(core.move({ x: 8, y: 9 }, 0, -1), { x: 8, y: 9 });
});
