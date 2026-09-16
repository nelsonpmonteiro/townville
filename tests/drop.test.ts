import { test } from "node:test";
import assert from "node:assert/strict";
import * as drag from "../src/drop";
test("drop accepts only release inside measured target, including its boundary", () => {
  assert.equal(typeof drag.inside, "function");
  const box = { x: 20, y: 40, width: 100, height: 60 };
  assert.equal(drag.inside({ x: 50, y: 60 }, box), true);
  assert.equal(drag.inside({ x: 20, y: 40 }, box), true);
  assert.equal(drag.inside({ x: 121, y: 60 }, box), false);
  assert.equal(drag.inside({ x: 50, y: 39 }, box), false);
  assert.equal(drag.inside({ x: 50, y: 60 }, null), false);
});
