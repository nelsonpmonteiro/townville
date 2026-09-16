import React, { useRef, useState } from "react";
import { ItemArt } from "./Art";
import { inside } from "./drop";
type Props = {
  kind: string;
  target: string;
  items: number[];
  selected: number | null;
  select: (id: number) => void;
  transfer: (id: number) => void;
  count: number;
};
export default function Collection({
  kind,
  target,
  items,
  selected,
  select,
  transfer,
  count,
}: Props) {
  const zone = useRef<HTMLButtonElement>(null);
  const [drag, setDrag] = useState<{ id: number; x: number; y: number } | null>(
    null,
  );
  const origin = useRef<{ x: number; y: number } | null>(null);
  return (
    <div
      style={{
        display: "flex",
        gap: 20,
        alignItems: "center",
        flexWrap: "wrap",
        justifyContent: "center",
        margin: "22px 0",
      }}
    >
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: 8,
          maxWidth: 370,
          minHeight: 160,
          alignContent: "center",
          background: "#f1ecd9",
          borderRadius: 22,
          padding: 18,
        }}
      >
        {items.map((id) => (
          <button
            key={id}
            aria-label={`${kind} ${id + 1}`}
            onClick={() => select(id)}
            onPointerDown={(e) => {
              e.currentTarget.setPointerCapture(e.pointerId);
              origin.current = { x: e.clientX, y: e.clientY };
              setDrag({ id, x: e.clientX, y: e.clientY });
            }}
            onPointerMove={(e) => {
              if (drag) setDrag({ ...drag, x: e.clientX, y: e.clientY });
            }}
            onPointerUp={(e) => {
              const r = zone.current?.getBoundingClientRect();
              if (inside({ x: e.clientX, y: e.clientY }, r)) {
                transfer(id);
                e.preventDefault();
              }
              setDrag(null);
            }}
            onPointerCancel={() => setDrag(null)}
            style={{
              touchAction: "none",
              cursor: "grab",
              border:
                selected === id ? "3px solid #5479e8" : "3px solid transparent",
              borderRadius: 15,
              background: "#fffcf3",
              padding: 2,
              opacity: drag?.id === id ? 0.6 : 1,
            }}
          >
            <ItemArt kind={kind} />
          </button>
        ))}
      </div>
      <button
        ref={zone}
        aria-label={target}
        onClick={() => {
          if (selected !== null) transfer(selected);
        }}
        style={{
          width: 220,
          minHeight: 195,
          border: "3px dashed #a9b788",
          borderRadius: 24,
          background: "#edf3df",
          color: "#405539",
          fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif",
          fontSize: 20,
          cursor: "pointer",
          padding: 18,
        }}
      >
        <div
          style={{
            fontSize: 13,
            textTransform: "uppercase",
            letterSpacing: 2,
            marginBottom: 12,
          }}
        >
          {target}
        </div>
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            flexWrap: "wrap",
          }}
        >
          {Array.from({ length: count }, (_, i) => (
            <ItemArt key={i} kind={kind} size={38} />
          ))}
        </div>
        <div style={{ marginTop: 12 }}>Collected: {count}</div>
        <div style={{ fontSize: 12, marginTop: 10 }}>Drop here · or tap</div>
      </button>
      {drag &&
        origin.current &&
        Math.abs(drag.x - origin.current.x) +
          Math.abs(drag.y - origin.current.y) >
          8 && (
          <div
            style={{
              position: "fixed",
              left: drag.x - 32,
              top: drag.y - 32,
              pointerEvents: "none",
              zIndex: 100,
            }}
          >
            <ItemArt kind={kind} />
          </div>
        )}
    </div>
  );
}
