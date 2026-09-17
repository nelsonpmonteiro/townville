// ============================================================
// GAME FLOW — pure state machine for the interaction loop.
//
//   idle → dialogue → quest → (success | failure) → idle
//
// NO React, NO side effects, NO imports of UI or storage.
// Every transition is a pure function: (state, event) → state.
// This is the contract that keeps mechanics stable: UI can be
// rewritten freely; these rules only change if the SPEC changes.
// ============================================================

import { DialogueTree } from '../types/dialogue';
import { QuestDefinition } from '../types/quest';
import { Save, completeEventPoint, recordError, getCurrentPhase } from '../core';
import { getContent } from '../content/registry';
import { DEFAULT_MAX_ATTEMPTS } from '../config';

// ---------- State ----------

export type FlowState =
  | { kind: 'idle' }
  | {
      kind: 'dialogue';
      npcId: string;
      phase: number;
      tree: DialogueTree;
      nodeId: string;
      /** Which conversation stage this dialogue belongs to. */
      stage: 'intro' | 'success' | 'failure';
    }
  | {
      kind: 'quest';
      npcId: string;
      phase: number;
      quest: QuestDefinition;
      attempts: number;
      errors: number;
    };

export const idle = (): FlowState => ({ kind: 'idle' });

// ---------- Events ----------

export type FlowEvent =
  | { type: 'INTERACT'; npcId: string } // player stepped on event point
  | { type: 'ADVANCE'; nodeId: string } // dialogue advanced to node
  | { type: 'ANSWER'; correct: boolean } // quest answer submitted
  | { type: 'CLOSE' }; // player closed/skipped

// ---------- Result of a transition ----------

export interface FlowResult {
  state: FlowState;
  /** Save mutation to apply, if any (null = no change). */
  save: Save | null;
  /** Side-effect the shell should perform (sound, celebration…). */
  effect: 'none' | 'quest-complete' | 'life-lost' | 'quest-failed';
}

const noSave = (state: FlowState): FlowResult => ({ state, save: null, effect: 'none' });

// ---------- Transitions ----------

export function reduce(state: FlowState, event: FlowEvent, save: Save): FlowResult {
  switch (event.type) {
    case 'INTERACT':
      return onInteract(state, event.npcId, save);
    case 'ADVANCE':
      return onAdvance(state, event.nodeId);
    case 'ANSWER':
      return onAnswer(state, event.correct, save);
    case 'CLOSE':
      return noSave(idle());
  }
}

function onInteract(state: FlowState, npcId: string, save: Save): FlowResult {
  // Only start an interaction from idle — never interrupt one.
  if (state.kind !== 'idle') return noSave(state);

  const phase = getCurrentPhase(save, npcId);
  if (phase > 4) return noSave(state); // all phases done

  const content = getContent(npcId, phase);
  if (!content) return noSave(state); // no content yet for this NPC/phase

  return noSave({
    kind: 'dialogue',
    npcId,
    phase,
    tree: content.dialogue,
    nodeId: content.dialogue.startNode,
    stage: 'intro',
  });
}

function onAdvance(state: FlowState, nodeId: string): FlowResult {
  if (state.kind !== 'dialogue') return noSave(state);

  const node = state.tree.nodes[nodeId];
  if (!node) return noSave(idle()); // broken tree — fail safe to idle

  // 'end' node semantics depend on the stage:
  if (node.type === 'end') {
    if (state.stage === 'intro' || state.stage === 'failure') {
      // intro ends → launch the quest
      // failure epilogue ends → retry the quest (fresh attempts)
      const content = getContent(state.npcId, state.phase);
      if (!content) return noSave(idle());
      return noSave({
        kind: 'quest',
        npcId: state.npcId,
        phase: state.phase,
        quest: content.quest,
        attempts: 0,
        errors: 0,
      });
    }
    // success epilogue ends → back to idle
    return noSave(idle());
  }

  return noSave({ ...state, nodeId });
}

function onAnswer(state: FlowState, correct: boolean, save: Save): FlowResult {
  if (state.kind !== 'quest') return noSave(state);

  const attempts = state.attempts + 1;

  if (correct) {
    const newSave = completeEventPoint(save, state.npcId, state.phase);
    const content = getContent(state.npcId, state.phase)!;
    const successNode = state.quest.successDialogue;
    return {
      state: {
        kind: 'dialogue',
        npcId: state.npcId,
        phase: state.phase,
        tree: content.dialogue,
        nodeId: successNode,
        stage: 'success',
      },
      save: newSave,
      effect: 'quest-complete',
    };
  }

  // Wrong answer
  const errors = state.errors + 1;
  const eventPointId = `${state.npcId}:${state.phase}`;
  const newSave = recordError(save, eventPointId);
  const lostLife = newSave.lives < save.lives;

  const maxAttempts = state.quest.maxAttempts ?? DEFAULT_MAX_ATTEMPTS;
  if (attempts >= maxAttempts) {
    // Out of attempts → failure dialogue
    const content = getContent(state.npcId, state.phase)!;
    return {
      state: {
        kind: 'dialogue',
        npcId: state.npcId,
        phase: state.phase,
        tree: content.dialogue,
        nodeId: state.quest.failureDialogue,
        stage: 'failure',
      },
      save: newSave,
      effect: lostLife ? 'life-lost' : 'quest-failed',
    };
  }

  // Still has attempts → stay in quest
  return {
    state: { ...state, attempts, errors },
    save: newSave,
    effect: lostLife ? 'life-lost' : 'none',
  };
}

// ---------- Queries (for the UI shell) ----------

/** Movement is only allowed while idle. */
export const canMove = (state: FlowState): boolean => state.kind === 'idle';

/** Current dialogue node, or null. */
export function currentNode(state: FlowState) {
  if (state.kind !== 'dialogue') return null;
  return state.tree.nodes[state.nodeId] ?? null;
}
