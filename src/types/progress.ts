// Progress tracking types per HERMES-implementation-instruction.md §6

export type BuildingState = 'LOCKED' | 'STAGE_1' | 'STAGE_2' | 'STAGE_3' | 'COMPLETE';

export interface DialogueState {
  currentNode: string | null;
  visitedNodes: string[];
  choices: Record<string, string>; // nodeId → chosen option
}

export interface PhaseProgress {
  completed: boolean;
  completedAt?: number; // timestamp
  score: number;
  attempts: number;
  errors: number;
}

export interface NPCProgress {
  id: string;
  unlocked: boolean;
  unlockedAt?: number;
  phase1: PhaseProgress;
  phase2: PhaseProgress;
  phase3: PhaseProgress;
  phase4: PhaseProgress;
  dialogue: DialogueState;
  buildingState: BuildingState;
}

export interface WorldProgress {
  id: string;
  unlocked: boolean;
  npcs: Record<string, NPCProgress>; // npcId → progress
  completed: boolean;
  completedAt?: number;
}

export interface Progress {
  currentWorld: 'farm' | 'downtown';
  worlds: {
    farm: WorldProgress;
    downtown: WorldProgress;
  };
  storyFlags: Record<string, boolean | number | string>;
  
  // Legacy fields from old Save type (keep for migration)
  lives: number;
  score: number;
  streak: number;
  sessionEvents: number;
}

// Helper to create fresh NPCProgress
export function createNPCProgress(id: string, unlocked = false): NPCProgress {
  const freshPhase = (): PhaseProgress => ({
    completed: false,
    score: 0,
    attempts: 0,
    errors: 0,
  });

  return {
    id,
    unlocked,
    phase1: freshPhase(),
    phase2: freshPhase(),
    phase3: freshPhase(),
    phase4: freshPhase(),
    dialogue: {
      currentNode: null,
      visitedNodes: [],
      choices: {},
    },
    buildingState: 'LOCKED',
  };
}

// Helper to create fresh WorldProgress
export function createWorldProgress(id: string, npcIds: string[]): WorldProgress {
  const npcs: Record<string, NPCProgress> = {};
  npcIds.forEach((npcId) => {
    npcs[npcId] = createNPCProgress(npcId, false);
  });
  
  return {
    id,
    unlocked: false,
    npcs,
    completed: false,
  };
}

// Get building state from completed phases
export function getBuildingState(phases: [boolean, boolean, boolean, boolean]): BuildingState {
  if (phases[3]) return 'COMPLETE';
  if (phases[2]) return 'STAGE_3';
  if (phases[1]) return 'STAGE_2';
  if (phases[0]) return 'STAGE_1';
  return 'LOCKED';
}
