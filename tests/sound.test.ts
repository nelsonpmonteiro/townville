import { test } from "node:test";
import assert from "node:assert/strict";
import * as sound from "../src/sound";
test("audio is gesture gated, muteable, and pauses while hidden", () => {
  assert.equal(typeof sound.SoundGate, "function");
  const calls: string[] = [];
  const gate = new sound.SoundGate({
    play: () => calls.push("play"),
    pause: () => calls.push("pause"),
  });
  gate.sync(false, false);
  assert.deepEqual(calls, ["pause"]);
  gate.gesture();
  assert.equal(calls.at(-1), "play");
  gate.sync(false, true);
  assert.equal(calls.at(-1), "pause");
  gate.sync(true, false);
  assert.equal(calls.at(-1), "pause");
  gate.sync(false, false);
  assert.equal(calls.at(-1), "play");
});
