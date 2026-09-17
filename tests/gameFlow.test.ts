// Contract tests for src/engine/gameFlow.ts — the interaction loop.
// idle → dialogue(intro) → quest → success/failure → idle
// These lock the FLOW. UI can change freely; this must not break.
import { test } from "node:test";
import assert from "node:assert/strict";
import * as core from "../src/core";
import {
  reduce,
  idle,
  canMove,
  currentNode,
  FlowState,
} from "../src/engine/gameFlow";
import { MAE_PHASE_1 } from "../src/data/dialogues/mae-phase1";
import { MAE_PHASE_1_QUEST } from "../src/data/quests/mae-phase1";

const fresh = core.fresh;

test("INTERACT with real content opens intro dialogue at startNode", () => {
  const r = reduce(idle(), { type: "INTERACT", npcId: "mae" }, fresh());
  assert.equal(r.state.kind, "dialogue");
  if (r.state.kind === "dialogue") {
    assert.equal(r.state.npcId, "mae");
    assert.equal(r.state.phase, 1);
    assert.equal(r.state.nodeId, MAE_PHASE_1.startNode);
    assert.equal(r.state.stage, "intro");
  }
  assert.equal(r.save, null); // interacting never mutates the save
});

test("INTERACT with unknown NPC or completed NPC stays idle", () => {
  // NPC without content
  const r1 = reduce(idle(), { type: "INTERACT", npcId: "billy" }, fresh());
  assert.equal(r1.state.kind, "idle");

  // NPC with all 4 phases done
  let s = fresh();
  for (const p of [1, 2, 3, 4]) s = core.completeEventPoint(s, "mae", p);
  const r2 = reduce(idle(), { type: "INTERACT", npcId: "mae" }, s);
  assert.equal(r2.state.kind, "idle");
});

test("INTERACT never interrupts an ongoing interaction", () => {
  const inDialogue = reduce(idle(), { type: "INTERACT", npcId: "mae" }, fresh()).state;
  const r = reduce(inDialogue, { type: "INTERACT", npcId: "mae" }, fresh());
  assert.deepEqual(r.state, inDialogue);
});

test("movement is locked during any interaction", () => {
  assert.equal(canMove(idle()), true);
  const inDialogue = reduce(idle(), { type: "INTERACT", npcId: "mae" }, fresh()).state;
  assert.equal(canMove(inDialogue), false);
});

test("intro dialogue 'end' node launches the quest with zero attempts", () => {
  const save = fresh();
  let st = reduce(idle(), { type: "INTERACT", npcId: "mae" }, save).state;
  // Walk intro.01 → intro.02 → intro.03 → knows.01 → quest_start (end)
  for (const nodeId of ["intro.02", "intro.03", "knows.01", "quest_start"]) {
    st = reduce(st, { type: "ADVANCE", nodeId }, save).state;
  }
  assert.equal(st.kind, "quest");
  if (st.kind === "quest") {
    assert.equal(st.quest.id, MAE_PHASE_1_QUEST.id);
    assert.equal(st.attempts, 0);
    assert.equal(st.errors, 0);
  }
});

test("correct answer: completes point (+100), enters success dialogue", () => {
  const save = fresh();
  const quest: FlowState = {
    kind: "quest", npcId: "mae", phase: 1,
    quest: MAE_PHASE_1_QUEST, attempts: 0, errors: 0,
  };
  const r = reduce(quest, { type: "ANSWER", correct: true }, save);

  assert.equal(r.effect, "quest-complete");
  assert.ok(r.save);
  assert.equal(r.save!.score, 100);
  assert.deepEqual(r.save!.completedEventPoints, ["mae:1"]);

  assert.equal(r.state.kind, "dialogue");
  if (r.state.kind === "dialogue") {
    assert.equal(r.state.stage, "success");
    assert.equal(r.state.nodeId, MAE_PHASE_1_QUEST.successDialogue);
  }
});

test("wrong answers: stay in quest until maxAttempts, then failure dialogue", () => {
  let save = fresh();
  let st: FlowState = {
    kind: "quest", npcId: "mae", phase: 1,
    quest: MAE_PHASE_1_QUEST, attempts: 0, errors: 0,
  };

  // Attempts 1 and 2: stay in quest
  for (let i = 1; i <= 2; i++) {
    const r = reduce(st, { type: "ANSWER", correct: false }, save);
    st = r.state;
    if (r.save) save = r.save;
    assert.equal(st.kind, "quest");
    if (st.kind === "quest") assert.equal(st.attempts, i);
  }

  // Attempt 3 (= maxAttempts): failure dialogue + life lost (3 errors)
  const r3 = reduce(st, { type: "ANSWER", correct: false }, save);
  if (r3.save) save = r3.save;
  assert.equal(r3.state.kind, "dialogue");
  if (r3.state.kind === "dialogue") {
    assert.equal(r3.state.stage, "failure");
    assert.equal(r3.state.nodeId, MAE_PHASE_1_QUEST.failureDialogue);
  }
  assert.equal(save.lives, 2); // 3rd error on mae:1 costs a life
  assert.equal(r3.effect, "life-lost");
  assert.equal(save.score, 0); // errors never touch score
});

test("failure dialogue end → quest relaunches with fresh attempts", () => {
  const save = fresh();
  const failureDialogue: FlowState = {
    kind: "dialogue", npcId: "mae", phase: 1,
    tree: MAE_PHASE_1, nodeId: "failure.01", stage: "failure",
  };
  // failure.01 → failure.02 → quest_start (end, in failure stage)
  let st = reduce(failureDialogue, { type: "ADVANCE", nodeId: "failure.02" }, save).state;
  st = reduce(st, { type: "ADVANCE", nodeId: "quest_start" }, save).state;
  assert.equal(st.kind, "quest");
  if (st.kind === "quest") assert.equal(st.attempts, 0);
});

test("success dialogue end → idle (loop closed)", () => {
  const save = core.completeEventPoint(fresh(), "mae", 1);
  const successDialogue: FlowState = {
    kind: "dialogue", npcId: "mae", phase: 1,
    tree: MAE_PHASE_1, nodeId: "success.01", stage: "success",
  };
  let st = reduce(successDialogue, { type: "ADVANCE", nodeId: "success.02" }, save).state;
  st = reduce(st, { type: "ADVANCE", nodeId: "complete" }, save).state;
  assert.equal(st.kind, "idle");
});

test("after completing phase 1, INTERACT offers phase 2 (no content → idle)", () => {
  const save = core.completeEventPoint(fresh(), "mae", 1);
  // Phase 2 has no content yet → must stay idle, NOT crash or repeat phase 1
  const r = reduce(idle(), { type: "INTERACT", npcId: "mae" }, save);
  assert.equal(r.state.kind, "idle");
});

test("CLOSE always returns to idle from any state", () => {
  const inDialogue = reduce(idle(), { type: "INTERACT", npcId: "mae" }, fresh()).state;
  assert.equal(reduce(inDialogue, { type: "CLOSE" }, fresh()).state.kind, "idle");

  const inQuest: FlowState = {
    kind: "quest", npcId: "mae", phase: 1,
    quest: MAE_PHASE_1_QUEST, attempts: 1, errors: 1,
  };
  assert.equal(reduce(inQuest, { type: "CLOSE" }, fresh()).state.kind, "idle");
});

test("broken dialogue node fails safe to idle (never crashes)", () => {
  const inDialogue = reduce(idle(), { type: "INTERACT", npcId: "mae" }, fresh()).state;
  const r = reduce(inDialogue, { type: "ADVANCE", nodeId: "nonexistent.node" }, fresh());
  assert.equal(r.state.kind, "idle");
});

test("currentNode returns the visible node or null", () => {
  assert.equal(currentNode(idle()), null);
  const st = reduce(idle(), { type: "INTERACT", npcId: "mae" }, fresh()).state;
  const node = currentNode(st);
  assert.ok(node);
  assert.equal(node!.id, MAE_PHASE_1.startNode);
});
