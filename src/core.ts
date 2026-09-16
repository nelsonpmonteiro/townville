export type Save = {
  version: 1;
  completed: string[];
  score: number;
  streak: number;
  upgrade: number;
  muted: boolean;
};
export const QUESTS = [
  { id: "q1", npc: "Mae", kind: "egg", target: "basket", count: 3 },
  { id: "q2", npc: "Chester", kind: "chick", target: "pen", count: 4 },
  { id: "q3", npc: "Lily", kind: "hay", target: "stable", count: 2 },
  { id: "q4", npc: "Mae", kind: "egg", target: "basket", count: 5 },
  { id: "q5", npc: "Chester", kind: "chick", target: "pen", count: 6 },
] as const;
export const fresh = (): Save => ({
  version: 1,
  completed: [],
  score: 0,
  streak: 0,
  upgrade: 0,
  muted: false,
});
export const sessionDone = (s: Save) => s.completed.length === 5;
export const available = (s: Save, npc: string) =>
  QUESTS[s.completed.length]?.npc === npc;
export function complete(s: Save, id: string, count: number): Save {
  const q = QUESTS[s.completed.length];
  if (!q || q.id !== id || q.count !== count) return s;
  const completed = [...s.completed, id];
  return {
    ...s,
    completed,
    score: completed.length * 100,
    streak: completed.length,
    upgrade: Math.min(3, completed.length),
  };
}
export const serialize = (s: Save) => JSON.stringify(s);
export function restore(raw: string | null): Save {
  try {
    const v = JSON.parse(raw ?? "null");
    if (
      v?.version !== 1 ||
      !Array.isArray(v.completed) ||
      v.completed.length > 5 ||
      v.completed.some((id: unknown, i: number) => id !== QUESTS[i]?.id)
    )
      return fresh();
    let s = fresh();
    for (const id of v.completed) {
      const q = QUESTS[s.completed.length];
      s = complete(s, id, q.count);
    }
    return { ...s, muted: v.muted === true };
  } catch {
    return fresh();
  }
}
export type Point = { x: number; y: number };
export const NPCS = [
  { name: "Mae", x: 8, y: 8 },
  { name: "Chester", x: 5, y: 6 },
  { name: "Lily", x: 14, y: 8 },
  { name: "Oliver", x: 3, y: 11 },
  { name: "June", x: 16, y: 11 },
  { name: "Finn", x: 11, y: 4 },
  { name: "Rosie", x: 6, y: 12 },
  { name: "Theo", x: 17, y: 5 },
];
export const BUILDINGS = [
  { x: 2, y: 2, w: 4, h: 3, name: "Hen house" },
  { x: 12, y: 2, w: 5, h: 3, name: "Stable" },
  { x: 12, y: 10, w: 4, h: 3, name: "Chick pen" },
];
export function move(p: Point, dx: number, dy: number): Point {
  const q = { x: p.x + dx, y: p.y + dy };
  if (
    q.x < 0 ||
    q.x >= 20 ||
    q.y < 0 ||
    q.y >= 15 ||
    BUILDINGS.some(
      (b) => q.x >= b.x && q.x < b.x + b.w && q.y >= b.y && q.y < b.y + b.h,
    ) ||
    NPCS.some((n) => n.x === q.x && n.y === q.y)
  )
    return p;
  return q;
}
