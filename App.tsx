import React, { useEffect, useState } from "react";
import { View, StyleSheet, Platform } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { WORLD_1_FARM } from "./src/data/worldMaps";
import {
  fresh,
  restore,
  serialize,
  Save,
  Point,
  canMoveTo,
} from "./src/core";
import WorldMapRenderer from "./src/WorldMapRenderer";
import GameHeader from "./src/GameHeader";

const KEY = "townville.save.v1";

export default function App() {
  const [save, setSave] = useState<Save>(fresh());
  const [ready, setReady] = useState(false);
  const [pos, setPos] = useState<Point>({ x: 13, y: 9 });

  useEffect(() => {
    AsyncStorage.getItem(KEY)
      .then((raw) => {
        const restored = restore(raw);
        setSave(restored);
        setReady(true);
      })
      .catch(() => {
        setReady(true);
      });
  }, []);

  useEffect(() => {
    if (ready) {
      AsyncStorage.setItem(KEY, serialize(save)).catch(() => {
        console.warn("Storage unavailable");
      });
    }
  }, [save, ready]);

  const walk = (dx: number, dy: number) => {
    setPos((p) => {
      const next = { x: p.x + dx, y: p.y + dy };
      if (canMoveTo(next, WORLD_1_FARM.collisionMap, [])) {
        return next;
      }
      return p;
    });
  };

  useEffect(() => {
    if (Platform.OS !== "web") return;

    const handler = (e: KeyboardEvent) => {
      const dirs: Record<string, [number, number]> = {
        ArrowUp: [0, -1],
        w: [0, -1],
        ArrowDown: [0, 1],
        s: [0, 1],
        ArrowLeft: [-1, 0],
        a: [-1, 0],
        ArrowRight: [1, 0],
        d: [1, 0],
      };

      if (dirs[e.key]) {
        e.preventDefault();
        const [dx, dy] = dirs[e.key];
        walk(dx, dy);
      }
    };

    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []); // Empty deps - walk uses setPos callback

  if (!ready) {
    return <View style={s.loading} />;
  }

  return (
    <View style={s.container}>
      <GameHeader
        lives={save.lives}
        maxLives={3}
        score={save.score}
        streak={save.streak}
        sessionProgress={save.sessionEvents}
        totalQuests={5}
      />
      <View style={s.viewport} nativeID="viewport">
        <View
          style={{
            transform: [
              { translateX: -Math.max(0, Math.min(pos.x * 48 - 600, 1440 - 1200)) },
              { translateY: -Math.max(0, Math.min(pos.y * 48 - 400, 960 - 800)) },
            ],
          }}
        >
          <WorldMapRenderer
            world={WORLD_1_FARM}
            protagonistPos={pos}
          />
        </View>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container: {
    flex: 1,
    width: "100%",
    height: "100%",
    backgroundColor: "#000",
    alignItems: "center",
    justifyContent: "center",
  },
  viewport: {
    width: 1200,
    height: 800,
    position: "relative",
    overflow: "hidden",
  },
  loading: {
    flex: 1,
    backgroundColor: "#1F2937",
  },
});
