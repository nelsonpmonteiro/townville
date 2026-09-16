import React, { useRef, useState, useMemo } from "react";
import { View, Pressable, Text, PanResponder } from "react-native";
import { ItemArt } from "./Art";
import { inside, Box } from "./drop";
type Props = {
  kind: string;
  target: string;
  items: number[];
  selected: number | null;
  select: (id: number) => void;
  transfer: (id: number) => void;
  count: number;
};
function Draggable({
  id,
  kind,
  selected,
  select,
  release,
}: {
  id: number;
  kind: string;
  selected: boolean;
  select: () => void;
  release: (x: number, y: number) => void;
}) {
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const handlers = useRef({ select, release });
  handlers.current = { select, release };
  const responder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderMove: (_, g) => setOffset({ x: g.dx, y: g.dy }),
        onPanResponderRelease: (_, g) => {
          setOffset({ x: 0, y: 0 });
          if (Math.abs(g.dx) + Math.abs(g.dy) < 8) handlers.current.select();
          else handlers.current.release(g.moveX, g.moveY);
        },
        onPanResponderTerminate: () => setOffset({ x: 0, y: 0 }),
      }),
    [],
  );
  return (
    <View
      {...responder.panHandlers}
      accessible
      accessibilityRole="button"
      accessibilityLabel={`${kind} ${id + 1}`}
      accessibilityActions={[{ name: "activate" }]}
      onAccessibilityAction={select}
      style={{
        transform: [{ translateX: offset.x }, { translateY: offset.y }],
        zIndex: offset.x || offset.y ? 10 : 0,
        backgroundColor: selected ? "#c2d3ff" : "#fff5de",
        borderRadius: 14,
      }}
    >
      <ItemArt kind={kind} />
    </View>
  );
}
export default function Collection({
  kind,
  target,
  items,
  selected,
  select,
  transfer,
  count,
}: Props) {
  const zone = useRef<View>(null);
  const release = (id: number, x: number, y: number) =>
    zone.current?.measureInWindow((bx, by, width, height) => {
      if (inside({ x, y }, { x: bx, y: by, width, height })) transfer(id);
    });
  return (
    <View style={{ gap: 20, marginVertical: 20 }}>
      <View
        style={{ flexDirection: "row", flexWrap: "wrap", gap: 8, zIndex: 2 }}
      >
        {items.map((id) => (
          <Draggable
            key={id}
            id={id}
            kind={kind}
            selected={selected === id}
            select={() => select(id)}
            release={(x, y) => release(id, x, y)}
          />
        ))}
      </View>
      <View ref={zone} collapsable={false}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={target}
          onPress={() => selected !== null && transfer(selected)}
          style={{
            padding: 24,
            backgroundColor: "#e5efd6",
            borderRadius: 20,
            minHeight: 140,
          }}
        >
          <Text>
            {target} · Collected: {count}
          </Text>
          <View style={{ flexDirection: "row", flexWrap: "wrap" }}>
            {Array.from({ length: count }, (_, i) => (
              <ItemArt key={i} kind={kind} size={35} />
            ))}
          </View>
        </Pressable>
      </View>
    </View>
  );
}
