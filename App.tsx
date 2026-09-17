import React, { useEffect, useState, useRef, useCallback, useMemo } from "react";
import { View, StyleSheet, Platform, Animated, Easing } from "react-native";
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
import { effectiveWalkableMap } from "./src/engine/collision";
import { computeBuildingStates } from "./src/state/buildingStates";
import WorldMapRenderer from "./src/WorldMapRenderer";
import GameHeader from "./src/GameHeader";
import { useViewportSize } from "./src/hooks/useViewportSize";
import {
  TILE_SIZE,
  MOVEMENT_DURATION_MS,
  MAX_LIVES,
  SESSION_QUEST_TARGET,
  SAVE_KEY,
  DEFAULT_MAX_ATTEMPTS,
} from "./src/config";

export default function App() {
  const mapWidth = WORLD_1_FARM.cols * TILE_SIZE;
  const mapHeight = WORLD_1_FARM.rows * TILE_SIZE;
  const [save, setSave] = useState<Save>(fresh());
  const [ready, setReady] = useState(false);
  const positionRef = useRef<Point>(WORLD_1_FARM.spawn);
  const [direction, setDirection] = useState<'front' | 'back' | 'left' | 'right'>('front');
  const [editMode, setEditMode] = useState(false);
  const [isMoving, setIsMoving] = useState(false);
  const [flow, setFlow] = useState<FlowState>(idle());

  // Animated position for smooth movement
  const animatedX = useRef(new Animated.Value(WORLD_1_FARM.spawn.x * TILE_SIZE)).current;
  const animatedY = useRef(new Animated.Value(WORLD_1_FARM.spawn.y * TILE_SIZE)).current;

  // Responsive viewport size
  const viewport = useViewportSize(mapWidth, mapHeight);

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

  // ---------- Derived state (single source: the save) ----------

  const buildingStates = useMemo(() => computeBuildingStates(save), [save]);
  const walkable = useMemo(() => effectiveWalkableMap(WORLD_1_FARM, save), [save]);
  const walkableRef = useRef(walkable);
  useEffect(() => { walkableRef.current = walkable; }, [walkable]);

  // Keep editor toggling active even while the movement listener is detached.
  useEffect(() => {
    if (Platform.OS !== 'web') return;
    const toggle = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'e' && !e.repeat) setEditMode(value => !value);
    };
    window.addEventListener('keydown', toggle);
    return () => window.removeEventListener('keydown', toggle);
  }, []);

  // ---------- Held-key movement ----------

  useEffect(() => {
    if (Platform.OS !== "web" || !ready || editMode) return;
    const keys = new Map<string, { delta: [number, number]; facing: typeof direction }>();
    const bindings: Record<string, { delta: [number, number]; facing: typeof direction }> = {
      ArrowUp: { delta: [0, -1], facing: 'back' }, w: { delta: [0, -1], facing: 'back' },
      ArrowDown: { delta: [0, 1], facing: 'front' }, s: { delta: [0, 1], facing: 'front' },
      ArrowLeft: { delta: [-1, 0], facing: 'left' }, a: { delta: [-1, 0], facing: 'left' },
      ArrowRight: { delta: [1, 0], facing: 'right' }, d: { delta: [1, 0], facing: 'right' },
    };
    let stepping = false;
    let disposed = false;
    let animation: Animated.CompositeAnimation | undefined;

    const stopInput = () => { keys.clear(); };
    const step = () => {
      if (disposed || stepping) return;
      const held = Array.from(keys.values());
      const input = held[held.length - 1];
      if (!input || !flowAllowsMovement(flowRef.current)) {
        setIsMoving(false);
        return;
      }
      const current = positionRef.current;
      const next = { x: current.x + input.delta[0], y: current.y + input.delta[1] };
      setDirection(input.facing);
      if (!canMoveTo(next, walkableRef.current)) {
        setIsMoving(false);
        return;
      }
      stepping = true;
      setIsMoving(true);
      animation = Animated.parallel([
        Animated.timing(animatedX, {
          toValue: next.x * TILE_SIZE, duration: MOVEMENT_DURATION_MS,
          easing: Easing.linear, useNativeDriver: false,
        }),
        Animated.timing(animatedY, {
          toValue: next.y * TILE_SIZE, duration: MOVEMENT_DURATION_MS,
          easing: Easing.linear, useNativeDriver: false,
        }),
      ]);
      animation.start(({ finished }) => {
        if (disposed) return;
        stepping = false;
        if (!finished) { stopInput(); setIsMoving(false); return; }
        positionRef.current = next;
        const ep = WORLD_1_FARM.eventPoints.find(p => p.x === next.x && p.y === next.y);
        if (ep) {
          stopInput();
          setIsMoving(false);
          dispatch({ type: 'INTERACT', npcId: ep.npcId });
          return;
        }
        // Chain the next tile without ever switching to idle in between.
        step();
      });
    };
    const keydown = (e: KeyboardEvent) => {
      const key = e.key.length === 1 ? e.key.toLowerCase() : e.key;
      const input = bindings[key];
      if (!input) return;
      e.preventDefault();
      if (e.repeat || !flowAllowsMovement(flowRef.current)) return;
      keys.delete(key);
      keys.set(key, input);
      step();
    };
    const keyup = (e: KeyboardEvent) => {
      const key = e.key.length === 1 ? e.key.toLowerCase() : e.key;
      if (bindings[key]) e.preventDefault();
      keys.delete(key);
      // A blocked step has no completion callback to restart held input.
      // Releasing the newer key must resume the remaining direction.
      if (bindings[key]) step();
    };
    const visibility = () => { if (document.hidden) stopInput(); };
    window.addEventListener('keydown', keydown);
    window.addEventListener('keyup', keyup);
    window.addEventListener('blur', stopInput);
    document.addEventListener('visibilitychange', visibility);
    return () => {
      disposed = true;
      stopInput();
      animation?.stop();
      animatedX.setValue(positionRef.current.x * TILE_SIZE);
      animatedY.setValue(positionRef.current.y * TILE_SIZE);
      setIsMoving(false);
      window.removeEventListener('keydown', keydown);
      window.removeEventListener('keyup', keyup);
      window.removeEventListener('blur', stopInput);
      document.removeEventListener('visibilitychange', visibility);
    };
  }, [ready, editMode, animatedX, animatedY, dispatch]);

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
            width: mapWidth,
            height: mapHeight,
            transform: [
              // Camera follow with clamped scroll. minScroll must stay <= 0:
              // when the viewport is LARGER than the map the range would
              // invert ([positive, 0]) and Animated throws "inputRange must
              // be monotonically non-decreasing" — clamp to [0,0] = centered
              // map, no scroll needed.
              {
                translateX: Animated.subtract(
                  viewport.width / 2,
                  Animated.add(animatedX, TILE_SIZE / 2)
                ).interpolate({
                  inputRange: [Math.min(0, -(mapWidth - viewport.width)), 0],
                  outputRange: [Math.min(0, -(mapWidth - viewport.width)), 0],
                  extrapolate: 'clamp',
                })
              },
              {
                translateY: Animated.subtract(
                  viewport.height / 2,
                  Animated.add(animatedY, TILE_SIZE / 2)
                ).interpolate({
                  inputRange: [Math.min(0, -(mapHeight - viewport.height)), 0],
                  outputRange: [Math.min(0, -(mapHeight - viewport.height)), 0],
                  extrapolate: 'clamp',
                })
              },
            ],
          }}
        >
          <WorldMapRenderer
            world={WORLD_1_FARM}
            save={save}
            protagonistAnimatedX={animatedX}
            protagonistAnimatedY={animatedY}
            protagonistDirection={direction}
            protagonistIsMoving={isMoving}
            buildingStates={buildingStates}
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
