// Core game logic for Townville MVP
// Pure functions - no React, no side effects

export type Save = {
  version: 1;
  currentWorld: number;
  completedEventPoints: string[]; // format: "npcId:phase" e.g. "mae:1", "chester:2"
  score: number;
  streak: number;
  lives: number;
  errors: Record<string, number>; // event point id -> error count  
  muted: boolean;
  sessionEvents: number; // 0-5 per session
};

export const fresh = (): Save => ({
  version: 1,
  currentWorld: 1,
  completedEventPoints: [],
  score: 0,
  streak: 0,
  lives: 3,
  errors: {},
  muted: false,
  sessionEvents: 0,
});

export const sessionDone = (s: Save) => s.sessionEvents >= 5;
export const gameOver = (s: Save) => s.lives <= 0;

export function recordError(s: Save, eventPointId: string): Save {
  const errorCount = (s.errors[eventPointId] || 0) + 1;
  const newErrors = { ...s.errors, [eventPointId]: errorCount };
  
  // Lose a life on 3rd error for this event point
  const lives = errorCount % 3 === 0 ? s.lives - 1 : s.lives;
  
  return {
    ...s,
    errors: newErrors,
    lives,
  };
}

export function completeEventPoint(s: Save, npcId: string, phase: number): Save {
  const eventPointId = `${npcId}:${phase}`;
  
  // Don't duplicate completions
  if (s.completedEventPoints.includes(eventPointId)) return s;
  
  const completedEventPoints = [...s.completedEventPoints, eventPointId];
  const sessionEvents = s.sessionEvents + 1;
  const newScore = s.score + 100;
  const newStreak = s.streak + 1;
  
  return {
    ...s,
    completedEventPoints,
    score: newScore,
    streak: newStreak,
    sessionEvents,
    errors: { ...s.errors, [eventPointId]: 0 }, // Reset errors for this point
  };
}

export function isEventPointCompleted(s: Save, npcId: string, phase: number): boolean {
  return s.completedEventPoints.includes(`${npcId}:${phase}`);
}

export function getCurrentPhase(s: Save, npcId: string): number {
  // Returns the next incomplete phase (1-4), or 5 if all done
  for (let phase = 1; phase <= 4; phase++) {
    if (!isEventPointCompleted(s, npcId, phase)) return phase;
  }
  return 5; // All phases complete
}

export function resetSession(s: Save): Save {
  return {
    ...s,
    lives: 3,
    errors: {},
    sessionEvents: 0,
  };
}

export const serialize = (s: Save) => JSON.stringify(s);

export function restore(raw: string | null): Save {
  try {
    const v = JSON.parse(raw ?? "null");
    if (v?.version !== 1) return fresh();
    
    return {
      version: 1,
      currentWorld: typeof v.currentWorld === 'number' ? v.currentWorld : 1,
      completedEventPoints: Array.isArray(v.completedEventPoints) ? v.completedEventPoints : [],
      score: typeof v.score === 'number' ? v.score : 0,
      streak: typeof v.streak === 'number' ? v.streak : 0,
      lives: typeof v.lives === 'number' && v.lives >= 0 ? v.lives : 3,
      errors: typeof v.errors === 'object' && v.errors !== null ? v.errors : {},
      muted: v.muted === true,
      sessionEvents: typeof v.sessionEvents === 'number' ? v.sessionEvents : 0,
    };
  } catch {
    return fresh();
  }
}

export type Point = { x: number; y: number };

export function isInBounds(p: Point, width: number, height: number): boolean {
  return p.x >= 0 && p.x < width && p.y >= 0 && p.y < height;
}

export function canWalkOn(tile: string): boolean {
  return tile === '.' || tile === 'E' || tile === 'S';
}

// Collision check for 30×20 grid
export function canMoveTo(
  p: Point,
  collisionMap: string[][],
  buildings: Array<{ x: number; y: number; w: number; h: number }>
): boolean {
  if (!isInBounds(p, 30, 20)) return false;
  
  const tile = collisionMap[p.y][p.x];
  if (!canWalkOn(tile)) return false;
  
  // Check buildings
  for (const b of buildings) {
    if (p.x >= b.x && p.x < b.x + b.w && p.y >= b.y && p.y < b.y + b.h) {
      return false;
    }
  }
  
  return true;
}
