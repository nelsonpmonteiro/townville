// Game state management with Progress system
// Per HERMES-implementation-instruction.md §6

import { Progress, createWorldProgress, createNPCProgress, NPCProgress, getBuildingState } from '../types/progress';
import { recalculateUnlocks } from '../data/story/conditions';
import { Save } from '../core';

// Farm NPCs
const FARM_NPC_IDS = ['mae', 'chester', 'lily', 'farmer-joe', 'grandma-rose', 'billy', 'vera', 'old-mac'];

// Downtown NPCs  
const DOWNTOWN_NPC_IDS = ['sam', 'rosa', 'tommy', 'chen', 'ms-park', 'carlos', 'danny', 'officer-pat'];

export function createFreshProgress(): Progress {
  const farmProgress = createWorldProgress('farm', FARM_NPC_IDS);
  const downtownProgress = createWorldProgress('downtown', DOWNTOWN_NPC_IDS);
  
  // Mae starts unlocked
  farmProgress.npcs.mae.unlocked = true;
  farmProgress.unlocked = true;
  
  return {
    currentWorld: 'farm',
    worlds: {
      farm: farmProgress,
      downtown: downtownProgress,
    },
    storyFlags: {},
    lives: 3,
    score: 0,
    streak: 0,
    sessionEvents: 0,
  };
}

// Complete a phase and update building state
export function completePhase(
  progress: Progress,
  worldId: 'farm' | 'downtown',
  npcId: string,
  phase: 1 | 2 | 3 | 4,
  score: number
): Progress {
  const newProgress = { ...progress };
  const npc = newProgress.worlds[worldId].npcs[npcId];
  
  if (!npc) return progress;
  
  const phaseKey = `phase${phase}` as 'phase1' | 'phase2' | 'phase3' | 'phase4';
  
  if (!npc[phaseKey].completed) {
    npc[phaseKey] = {
      completed: true,
      completedAt: Date.now(),
      score,
      attempts: npc[phaseKey].attempts + 1,
      errors: npc[phaseKey].errors,
    };
    
    // Update building state
    const phases: [boolean, boolean, boolean, boolean] = [
      npc.phase1.completed,
      npc.phase2.completed,
      npc.phase3.completed,
      npc.phase4.completed,
    ];
    npc.buildingState = getBuildingState(phases);
    
    // Update global score/streak
    newProgress.score += score;
    newProgress.streak += 1;
    newProgress.sessionEvents += 1;
    
    // Recalculate unlocks after completing a phase
    recalculateUnlocks(newProgress, worldId);
  }
  
  return newProgress;
}

// Record error for a phase
export function recordPhaseError(
  progress: Progress,
  worldId: 'farm' | 'downtown',
  npcId: string,
  phase: 1 | 2 | 3 | 4
): Progress {
  const newProgress = { ...progress };
  const npc = newProgress.worlds[worldId].npcs[npcId];
  
  if (!npc) return progress;
  
  const phaseKey = `phase${phase}` as 'phase1' | 'phase2' | 'phase3' | 'phase4';
  npc[phaseKey].errors += 1;
  
  // Lose life every 3 errors
  if (npc[phaseKey].errors % 3 === 0) {
    newProgress.lives -= 1;
  }
  
  return newProgress;
}

// Migrate old Save to new Progress
export function migrateFromSave(save: Save): Progress {
  const progress = createFreshProgress();
  
  // Copy simple fields
  progress.lives = save.lives;
  progress.score = save.score;
  progress.streak = save.streak;
  progress.sessionEvents = save.sessionEvents;
  progress.currentWorld = save.currentWorld === 1 ? 'farm' : 'downtown';
  
  // Migrate completedEventPoints ("npcId:phase" → phase completion)
  save.completedEventPoints.forEach((entry) => {
    const [npcId, phaseStr] = entry.split(':');
    const phase = parseInt(phaseStr, 10) as 1 | 2 | 3 | 4;
    
    // Find NPC in farm or downtown
    let worldId: 'farm' | 'downtown' = 'farm';
    let npc = progress.worlds.farm.npcs[npcId];
    
    if (!npc) {
      worldId = 'downtown';
      npc = progress.worlds.downtown.npcs[npcId];
    }
    
    if (npc) {
      const phaseKey = `phase${phase}` as 'phase1' | 'phase2' | 'phase3' | 'phase4';
      npc[phaseKey].completed = true;
      
      // Update building state
      const phases: [boolean, boolean, boolean, boolean] = [
        npc.phase1.completed,
        npc.phase2.completed,
        npc.phase3.completed,
        npc.phase4.completed,
      ];
      npc.buildingState = getBuildingState(phases);
    }
  });
  
  // Recalculate all unlocks
  recalculateUnlocks(progress, 'farm');
  recalculateUnlocks(progress, 'downtown');
  
  return progress;
}

// Convert Progress back to Save for persistence
export function progressToSave(progress: Progress): Save {
  const completedEventPoints: string[] = [];
  
  // Convert all completed phases back to "npcId:phase" format
  ['farm', 'downtown'].forEach((worldId) => {
    const world = progress.worlds[worldId as 'farm' | 'downtown'];
    Object.values(world.npcs).forEach((npc) => {
      if (npc.phase1.completed) completedEventPoints.push(`${npc.id}:1`);
      if (npc.phase2.completed) completedEventPoints.push(`${npc.id}:2`);
      if (npc.phase3.completed) completedEventPoints.push(`${npc.id}:3`);
      if (npc.phase4.completed) completedEventPoints.push(`${npc.id}:4`);
    });
  });
  
  return {
    version: 1,
    currentWorld: progress.currentWorld === 'farm' ? 1 : 2,
    completedEventPoints,
    score: progress.score,
    streak: progress.streak,
    lives: progress.lives,
    errors: {}, // Legacy field
    muted: false,
    sessionEvents: progress.sessionEvents,
  };
}
