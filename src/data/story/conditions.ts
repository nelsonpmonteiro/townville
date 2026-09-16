// NPC unlock conditions per HERMES-implementation-instruction.md §5
// Direct copy from townville_mvp_narrative_worlds_1_2.md §28-29

import { Progress } from '../types/progress';

type UnlockCondition = (p: Progress) => boolean;

// World 1 - Farm
export const FARM_UNLOCKS: Record<string, UnlockCondition> = {
  mae: () => true, // Always unlocked (starting NPC)
  
  chester: (p) => p.worlds.farm.npcs.mae?.phase1.completed ?? false,
  
  lily: (p) => p.worlds.farm.npcs.mae?.phase2.completed ?? false,
  
  'farmer-joe': (p) => p.worlds.farm.npcs.lily?.phase2.completed ?? false,
  
  'grandma-rose': (p) => {
    const chester = p.worlds.farm.npcs.chester;
    const lily = p.worlds.farm.npcs.lily;
    return (chester?.phase2.completed && lily?.phase1.completed) ?? false;
  },
  
  billy: (p) => p.worlds.farm.npcs.mae?.phase3.completed ?? false,
  
  vera: (p) => {
    const lily = p.worlds.farm.npcs.lily;
    const joe = p.worlds.farm.npcs['farmer-joe'];
    return (lily?.phase3.completed && joe?.phase2.completed) ?? false;
  },
  
  'old-mac': (p) => {
    const npcs = p.worlds.farm.npcs;
    return (
      npcs.mae?.phase2.completed &&
      npcs.chester?.phase2.completed &&
      npcs.lily?.phase2.completed &&
      npcs['farmer-joe']?.phase2.completed &&
      npcs['grandma-rose']?.phase2.completed &&
      npcs.billy?.phase2.completed &&
      npcs.vera?.phase2.completed
    ) ?? false;
  },
};

// World 2 - Downtown
export const DOWNTOWN_UNLOCKS: Record<string, UnlockCondition> = {
  sam: () => true, // Always unlocked (starting NPC)
  
  rosa: (p) => p.worlds.downtown.npcs.sam?.phase1.completed ?? false,
  
  tommy: (p) => p.worlds.downtown.npcs.sam?.phase2.completed ?? false,
  
  chen: (p) => p.worlds.downtown.npcs.rosa?.phase2.completed ?? false,
  
  'ms-park': (p) => p.worlds.downtown.npcs.chen?.phase1.completed ?? false,
  
  carlos: (p) => p.worlds.downtown.npcs.chen?.phase2.completed ?? false,
  
  danny: (p) => {
    const tommy = p.worlds.downtown.npcs.tommy;
    const msPark = p.worlds.downtown.npcs['ms-park'];
    return (tommy?.phase3.completed && msPark?.phase3.completed) ?? false;
  },
  
  'officer-pat': (p) => {
    const npcs = p.worlds.downtown.npcs;
    return (
      npcs.sam?.phase2.completed &&
      npcs.rosa?.phase2.completed &&
      npcs.chen?.phase2.completed &&
      npcs.tommy?.phase2.completed &&
      npcs['ms-park']?.phase2.completed &&
      npcs.carlos?.phase2.completed &&
      npcs.danny?.phase2.completed
    ) ?? false;
  },
};

// Recalculate all unlocks for a world
export function recalculateUnlocks(progress: Progress, worldId: 'farm' | 'downtown'): void {
  const unlocks = worldId === 'farm' ? FARM_UNLOCKS : DOWNTOWN_UNLOCKS;
  const worldProgress = progress.worlds[worldId];
  
  Object.keys(unlocks).forEach((npcId) => {
    const npc = worldProgress.npcs[npcId];
    if (npc && !npc.unlocked) {
      const shouldUnlock = unlocks[npcId](progress);
      if (shouldUnlock) {
        npc.unlocked = true;
        npc.unlockedAt = Date.now();
      }
    }
  });
}
