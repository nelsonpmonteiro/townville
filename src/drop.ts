export type Box = { x: number; y: number; width: number; height: number };
export function inside(p: { x: number; y: number }, b: Box | null | undefined) {
  return (
    !!b &&
    p.x >= b.x &&
    p.x <= b.x + b.width &&
    p.y >= b.y &&
    p.y <= b.y + b.height
  );
}
