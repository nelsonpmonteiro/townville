// ============================================================
// Building states — PURE selector from Save.
// Single source of truth for what every building looks like.
// App.tsx must never hardcode states; it calls computeBuildingStates.
//
// Rules (MVP spec):
// - NPC buildings progress with their NPC's completed phases:
//   0 done → LOCKED, 1 → STAGE_1, 2 → STAGE_2, 3 → STAGE_3, 4 → COMPLETE
// - farm-gate / town-gate: COMPLETE (open) only when EVERY event-point
//   NPC of that world has all 4 phases done; otherwise LOCKED (closed).
// ============================================================

import { Save, isEventPointCompleted } from '../core';
import { BuildingState } from '../types/progress';

// npcId → buildingId (World 1 + World 2)
const NPC_BUILDING: Record<string, string> = {
  // World 1 — Farm
  'mae': 'henhouse',
  'chester': 'stable',
  'farmer-joe': 'barn',
  'lily': 'coop',
  'vera': 'clinic',
  'grandma-rose': 'garden',
  // World 2 — Downtown
  'sam': 'bakery',
  'rosa': 'hardware',
  'mayor-chen': 'town-hall',
  'tommy': 'post-office',
  'ms-park': 'library',
  'danny': 'park',
};

// Event-point NPCs per world (gate opens when ALL are fully complete)
export const FARM_NPCS = ['mae', 'chester', 'lily', 'farmer-joe', 'vera', 'grandma-rose', 'billy'];
export const DOWNTOWN_NPCS = ['sam', 'rosa', 'mayor-chen', 'tommy', 'ms-park', 'danny', 'carlos', 'officer-pat'];

export function completedPhaseCount(save: Save, npcId: string): number {
  let n = 0;
  for (let phase = 1; phase <= 4; phase++) {
    if (isEventPointCompleted(save, npcId, phase)) n++;
  }
  return n;
}

export function stateFromPhaseCount(count: number): BuildingState {
  if (count >= 4) return 'COMPLETE';
  if (count === 3) return 'STAGE_3';
  if (count === 2) return 'STAGE_2';
  if (count === 1) return 'STAGE_1';
  return 'LOCKED';
}

export function allNpcsComplete(save: Save, npcIds: string[]): boolean {
  return npcIds.every((id) => completedPhaseCount(save, id) >= 4);
}

/** Derive every building's visual state from the save. */
export function computeBuildingStates(save: Save): Record<string, BuildingState> {
  const states: Record<string, BuildingState> = {};

  for (const [npcId, buildingId] of Object.entries(NPC_BUILDING)) {
    states[buildingId] = stateFromPhaseCount(completedPhaseCount(save, npcId));
  }

  states['farm-gate'] = allNpcsComplete(save, FARM_NPCS) ? 'COMPLETE' : 'LOCKED';
  states['town-gate'] = allNpcsComplete(save, DOWNTOWN_NPCS) ? 'COMPLETE' : 'LOCKED';
  // Fountain is decorative; always shown as built
  states['fountain'] = 'COMPLETE';

  return states;
}
