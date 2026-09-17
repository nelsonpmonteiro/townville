import React, { useEffect, useState, useRef, useCallback } from "react";
import { View, StyleSheet, Platform, Animated } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { WORLD_1_FARM } from "./src/data/worldMaps";
import MapEditor from "./src/components/MapEditor";
import DialogueBox from "./src/components/DialogueBox";
import QuestUI from "./src/components/QuestUI";
import { fresh, restore, serialize, Save, Point, canMoveTo } from "./src/core";
import {
  FlowState,
  FlowEvent,
  idle,
  reduce,
  canMove as flowAllowsMovement,
  currentNode,
} from "./src/engine/gameFlow";
import WorldMapRenderer from "./src/WorldMapRenderer";
import GameHeader from "./src/GameHeader";
import { useViewportSize } from "./src/hooks/useViewportSize";
import {
  TILE_SIZE,
  MAP_WIDTH,
  MAP_HEIGHT,
  MOVEMENT_DURATION_MS,
  MOVE_THROTTLE_MS,
  MAX_LIVES,
  SESSION_QUEST_TARGET,
  SAVE_KEY,
  DEFAULT_MAX_ATTEMPTS,
} from "./src/config";

export default function App() {
  const [save, setSave] = useState<Save>(fresh());
  const [ready, setReady] = useState(false);
  const [pos, setPos] = useState<Point>(WORLD_1_FARM.spawn);
  const [direction, setDirection] = useState<'front' | 'back' | 'left' | 'right'>('front');
  const [editMode, setEditMode] = useState(false);
  const [isMoving, setIsMoving] = useState(false);
  const [flow, setFlow] = useState<FlowState>(idle());

  // Animated position for smooth movement
  const animatedX = useRef(new Animated.Value(WORLD_1_FARM.spawn.x * TILE_SIZE)).current;
  const animatedY = useRef(new Animated.Value(WORLD_1_FARM.spawn.y * TILE_SIZE)).current;

  // Responsive viewport size
  const viewport = useViewportSize();

  // ---------- Persistence ----------

  useEffect(() => {
    AsyncStorage.getItem(SAVE_KEY)
      .then((raw) => {
        setSave(restore(raw));
        setReady(true);
      })
      .catch(() => setReady(true));
  }, []);

  useEffect(() => {
    if (ready) {
      AsyncStorage.setItem(SAVE_KEY, serialize(save)).catch(() => {
        console.warn("Storage unavailable");
      });
    }
  }, [save, ready]);

  // ---------- Game flow (single entry point for ALL interaction events) ----------

  const dispatch = useCallback((event: FlowEvent) => {
    setSave((currentSave) => {
      const result = reduce(flowRef.current, event, currentSave);
      flowRef.current = result.state;
      setFlow(result.state);
      // Effects (sound/celebration hooks) can branch on result.effect here
      return result.save ?? currentSave;
    });
  }, []);

  // Ref mirror so dispatch always sees the latest flow without re-binding
  const flowRef = useRef<FlowState>(flow);
  useEffect(() => { flowRef.current = flow; }, [flow]);

  // ---------- Movement ----------

  const lastMoveTimeRef = useRef(0);

  const tryMove = useCallback((dir: [number, number]) => {
    setPos((current) => {
      const next = { x: current.x + dir[0], y: current.y + dir[1] };
      if (!canMoveTo(next, WORLD_1_FARM.walkableMap)) return current;

      setIsMoving(true);
      Animated.parallel([
        Animated.timing(animatedX, {
          toValue: next.x * TILE_SIZE,
          duration: MOVEMENT_DURATION_MS,
          useNativeDriver: false,
        }),
        Animated.timing(animatedY, {
          toValue: next.y * TILE_SIZE,
          duration: MOVEMENT_DURATION_MS,
          useNativeDriver: false,
        }),
      ]).start(() => {
        setIsMoving(false);
        // Event point check AFTER the step lands
        const ep = WORLD_1_FARM.eventPoints.find(
          (p) => p.x === next.x && p.y === next.y
        );
        if (ep) dispatch({ type: 'INTERACT', npcId: ep.npcId });
      });

      return next;
    });
  }, [animatedX, animatedY, dispatch]);

  // ---------- Keyboard ----------

  useEffect(() => {
    if (Platform.OS !== "web") return;

    const handler = (e: KeyboardEvent) => {
      // Toggle edit mode with 'E'
      if (e.key === 'e' || e.key === 'E') {
        setEditMode((prev) => !prev);
        return;
      }
      if (editMode) return;
      if (!flowAllowsMovement(flowRef.current)) return; // locked during interactions

      let dir: [number, number] | null = null;
      if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') {
        dir = [0, -1]; setDirection('back');
      } else if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') {
        dir = [0, 1]; setDirection('front');
      } else if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') {
        dir = [-1, 0]; setDirection('left');
      } else if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') {
        dir = [1, 0]; setDirection('right');
      }
      if (!dir) return;

      const now = Date.now();
      if (now - lastMoveTimeRef.current < MOVE_THROTTLE_MS) return;
      lastMoveTimeRef.current = now;

      e.preventDefault();
      tryMove(dir);
    };

    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [editMode, tryMove]);

  // ---------- Render ----------

  if (!ready) {
    return <View style={s.loading} />;
  }

  if (editMode) {
    return (
      <MapEditor
        world={WORLD_1_FARM}
        onSave={() => {
          console.log('✅ Positions saved! Copy code from console');
        }}
        onClose={() => setEditMode(false)}
      />
    );
  }

  const dialogueNode = currentNode(flow);

  return (
    <View style={s.container}>
      <GameHeader
        lives={save.lives}
        maxLives={MAX_LIVES}
        score={save.score}
        streak={save.streak}
        sessionProgress={save.sessionEvents}
        totalQuests={SESSION_QUEST_TARGET}
      />
      <View style={[s.viewport, { width: viewport.width, height: viewport.height }]} nativeID="viewport">
        <Animated.View
          style={{
            width: MAP_WIDTH,
            height: MAP_HEIGHT,
            transform: [
              {
                translateX: Animated.subtract(
                  viewport.width / 2,
                  Animated.add(animatedX, TILE_SIZE / 2)
                ).interpolate({
                  inputRange: [-(MAP_WIDTH - viewport.width), 0],
                  outputRange: [-(MAP_WIDTH - viewport.width), 0],
                  extrapolate: 'clamp',
                })
              },
              {
                translateY: Animated.subtract(
                  viewport.height / 2,
                  Animated.add(animatedY, TILE_SIZE / 2)
                ).interpolate({
                  inputRange: [-(MAP_HEIGHT - viewport.height), 0],
                  outputRange: [-(MAP_HEIGHT - viewport.height), 0],
                  extrapolate: 'clamp',
                })
              },
            ],
          }}
        >
          <WorldMapRenderer
            world={WORLD_1_FARM}
            protagonistAnimatedX={animatedX}
            protagonistAnimatedY={animatedY}
            protagonistDirection={direction}
            protagonistIsMoving={isMoving}
            buildingStates={{}}
          />
        </Animated.View>
      </View>

      {/* Dialogue System */}
      {flow.kind === 'dialogue' && dialogueNode && (
        <DialogueBox
          node={dialogueNode}
          onChoice={(nextNodeId) => dispatch({ type: 'ADVANCE', nodeId: nextNodeId })}
          onNext={() => {
            if (dialogueNode.next) dispatch({ type: 'ADVANCE', nodeId: dialogueNode.next });
            else if (dialogueNode.type === 'end') dispatch({ type: 'ADVANCE', nodeId: dialogueNode.id });
          }}
          onSkip={() => dispatch({ type: 'CLOSE' })}
        />
      )}

      {/* Quest System */}
      {flow.kind === 'quest' && (
        <QuestUI
          quest={flow.quest}
          onSubmit={(_answer, isCorrect) => dispatch({ type: 'ANSWER', correct: isCorrect })}
          onCancel={() => dispatch({ type: 'CLOSE' })}
          attempts={flow.attempts}
          maxAttempts={flow.quest.maxAttempts ?? DEFAULT_MAX_ATTEMPTS}
        />
      )}
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
    position: "relative",
    overflow: "hidden",
  },
  loading: {
    flex: 1,
    backgroundColor: "#1F2937",
  },
});
