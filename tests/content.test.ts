// Content integrity tests — every dialogue/quest wired in the registry
// must be internally consistent. Catches broken node references at
// test time instead of as runtime dead-ends for a child player.
import { test } from "node:test";
import assert from "node:assert/strict";
import { getContent, npcIdsWithContent } from "../src/content/registry";

function collectPhases(): Array<{ key: string; npcId: string; phase: number }> {
  const out: Array<{ key: string; npcId: string; phase: number }> = [];
  for (const npcId of npcIdsWithContent()) {
    for (let phase = 1; phase <= 4; phase++) {
      if (getContent(npcId, phase)) out.push({ key: `${npcId}:${phase}`, npcId, phase });
    }
  }
  return out;
}

test("registry has at least one playable phase", () => {
  assert.ok(collectPhases().length >= 1);
});

test("every dialogue tree: startNode exists, all next/choice targets exist", () => {
  for (const { key, npcId, phase } of collectPhases()) {
    const { dialogue } = getContent(npcId, phase)!;
    assert.ok(dialogue.nodes[dialogue.startNode], `${key}: startNode missing`);

    for (const [id, node] of Object.entries(dialogue.nodes)) {
      assert.equal(node.id, id, `${key}: node key '${id}' ≠ node.id '${node.id}'`);

      if (node.next) {
        assert.ok(dialogue.nodes[node.next], `${key}: '${id}'.next → missing '${node.next}'`);
      }
      for (const choice of node.choices ?? []) {
        assert.ok(dialogue.nodes[choice.next], `${key}: '${id}' choice → missing '${choice.next}'`);
      }

      // Non-end nodes must lead somewhere (no dead ends)
      if (node.type !== "end") {
        assert.ok(
          node.next || (node.choices && node.choices.length > 0),
          `${key}: node '${id}' is a dead end (no next, no choices)`
        );
      }
    }
  }
});

test("every quest: success/failure dialogues exist in the SAME tree; sane answer", () => {
  for (const { key, npcId, phase } of collectPhases()) {
    const { dialogue, quest } = getContent(npcId, phase)!;

    assert.equal(quest.npcId, npcId, `${key}: quest.npcId mismatch`);
    assert.equal(quest.phase, phase, `${key}: quest.phase mismatch`);
    assert.ok(
      dialogue.nodes[quest.successDialogue],
      `${key}: successDialogue '${quest.successDialogue}' missing from tree`
    );
    assert.ok(
      dialogue.nodes[quest.failureDialogue],
      `${key}: failureDialogue '${quest.failureDialogue}' missing from tree`
    );
    assert.ok(
      quest.correctAnswer !== undefined && quest.correctAnswer !== "",
      `${key}: quest has no correctAnswer`
    );
    assert.ok((quest.maxAttempts ?? 3) >= 1, `${key}: maxAttempts must be >= 1`);
  }
});

test("every dialogue tree has at least one 'end' node (dialogues can finish)", () => {
  for (const { key, npcId, phase } of collectPhases()) {
    const { dialogue } = getContent(npcId, phase)!;
    const hasEnd = Object.values(dialogue.nodes).some((n) => n.type === "end");
    assert.ok(hasEnd, `${key}: dialogue tree never ends`);
  }
});
