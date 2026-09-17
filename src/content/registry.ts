// ============================================================
// CONTENT REGISTRY — the ONLY place where NPC content is wired.
// To add a new NPC phase: import its dialogue + quest and add
// one entry to CONTENT. Nothing else in the app changes.
//
// App.tsx and gameFlow.ts read content EXCLUSIVELY through
// getContent() — never import dialogue/quest files elsewhere.
// ============================================================

import { DialogueTree } from '../types/dialogue';
import { QuestDefinition } from '../types/quest';

import { MAE_PHASE_1 } from '../data/dialogues/mae-phase1';
import { MAE_PHASE_1_QUEST } from '../data/quests/mae-phase1';

export interface PhaseContent {
  dialogue: DialogueTree;
  quest: QuestDefinition;
}

// Key format: `${npcId}:${phase}` — matches Save.completedEventPoints
const CONTENT: Record<string, PhaseContent> = {
  'mae:1': { dialogue: MAE_PHASE_1, quest: MAE_PHASE_1_QUEST },
  // 'mae:2': { dialogue: MAE_PHASE_2, quest: MAE_PHASE_2_QUEST },
  // 'chester:1': { dialogue: CHESTER_PHASE_1, quest: CHESTER_PHASE_1_QUEST },
  // ... add new phases here, one line each
};

export function getContent(npcId: string, phase: number): PhaseContent | null {
  return CONTENT[`${npcId}:${phase}`] ?? null;
}

export function hasContent(npcId: string, phase: number): boolean {
  return `${npcId}:${phase}` in CONTENT;
}

/** All npcIds that have at least one phase of real content. */
export function npcIdsWithContent(): string[] {
  return [...new Set(Object.keys(CONTENT).map((k) => k.split(':')[0]))];
}
