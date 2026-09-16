import React, { useEffect, useState, useRef, useCallback } from "react";
import { View, StyleSheet, Platform, Animated } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { WORLD_1_FARM } from "./src/data/worldMaps";
import MapEditor from "./src/components/MapEditor";
import DialogueBox from "./src/components/DialogueBox";
import QuestUI from "./src/components/QuestUI";
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
import { useInteraction } from "./src/hooks/useInteraction";
import { useViewportSize } from "./src/hooks/useViewportSize";
import { MAE_PHASE_1 } from "./src/data/dialogues/mae-phase1";
import { MAE_PHASE_1_QUEST } from "./src/data/quests/mae-phase1";

const TILE_SIZE = 48;
const MAP_WIDTH = 40 * TILE_SIZE; // 1920px (40 cols)
const MAP_HEIGHT = 30 * TILE_SIZE; // 1440px (30 rows)
const MOVEMENT_DURATION = 200; // ms for smooth tile-to-tile movement

export default function App() {
  const [save, setSave] = useState<Save>(fresh());
  const [ready, setReady] = useState(false);
  const [pos, setPos] = useState<Point>({ x: 20, y: 7 }); // Match spawn from WORLD_1_FARM
  const [direction, setDirection] = useState<'front' | 'back' | 'left' | 'right'>('front');
  const [editMode, setEditMode] = useState(false);
  const [isMoving, setIsMoving] = useState(false);
  
  // Animated position for smooth movement
  const animatedX = useRef(new Animated.Value(20 * TILE_SIZE)).current;
  const animatedY = useRef(new Animated.Value(7 * TILE_SIZE)).current;
  
  // Responsive viewport size
  const viewport = useViewportSize();
  
  // Interaction system
  const interaction = useInteraction();

const KEY = "townville.save.v1";

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

  const walk = useCallback((dir: [number, number]) => {
    if (isMoving) {
      console.log('⏸️ Already moving, ignoring input');
      return;
    }
    
    // Update direction based on movement
    if (dir[0] === -1) setDirection('left');
    else if (dir[0] === 1) setDirection('right');
    else if (dir[1] === -1) setDirection('back');
    else if (dir[1] === 1) setDirection('front');
    
    const next = { x: pos.x + dir[0], y: pos.y + dir[1] };
    console.log('🚶 Walk attempt:', { from: pos, to: next, dir });
    
    // Use walkableMap instead of collisionMap (40×30 grid)
    const canMove = canMoveTo(next, WORLD_1_FARM.walkableMap, []);
    console.log('🔍 Can move?', canMove, 'Tile:', WORLD_1_FARM.walkableMap[next.y]?.[next.x]);
    
    if (canMove) {
      console.log('✅ Moving to', next);
      setIsMoving(true);
      
      // Animate to new position
      Animated.parallel([
        Animated.timing(animatedX, {
          toValue: next.x * TILE_SIZE,
          duration: MOVEMENT_DURATION,
          useNativeDriver: false, // Web doesn't support native driver
        }),
        Animated.timing(animatedY, {
          toValue: next.y * TILE_SIZE,
          duration: MOVEMENT_DURATION,
          useNativeDriver: false, // Web doesn't support native driver
        }),
      ]).start(() => {
        console.log('✅ Animation complete, new pos:', next);
        setIsMoving(false);
        setPos(next);
        checkEventPointCollision(next);
      });
    } else {
      console.log('🚫 Movement blocked at', next);
    }
  }, [isMoving, pos, animatedX, animatedY]);

  // Check if player stepped on an event point
  const checkEventPointCollision = (playerPos: Point) => {
    const eventPoint = WORLD_1_FARM.eventPoints.find(
      (ep) => ep.x === playerPos.x && ep.y === playerPos.y
    );

    if (eventPoint) {
      handleEventPointInteraction(eventPoint.npcId);
    }
  };

  // Handle NPC interaction based on npcId
  const handleEventPointInteraction = (npcId: string) => {
    // For now, only Mae Phase 1 is implemented
    if (npcId === 'mae') {
      interaction.startDialogue(MAE_PHASE_1);
    }
    // TODO: Add other NPCs as content is created
  };

  useEffect(() => {
    if (Platform.OS !== "web") return;

    const handler = (e: KeyboardEvent) => {
      // Toggle edit mode with 'E' key
      if (e.key === 'e' || e.key === 'E') {
        setEditMode(prev => !prev);
        return;
      }
      
      if (editMode) return; // Disable movement in edit mode
      
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
        walk(dirs[e.key]); // Pass array directly
      }
    };

    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [editMode, walk]); // walk is now stable with useCallback

  // Handle dialogue advancement
  const handleDialogueChoice = (nextNodeId: string, isCorrect?: boolean) => {
    if (interaction.state.type !== 'dialogue') return;

    const nextNode = interaction.state.tree.nodes[nextNodeId];
    
    // If this leads to quest_start, launch the quest
    if (nextNode && nextNode.id === 'quest_start') {
      interaction.advanceDialogue(nextNodeId);
      // Wait a moment, then start quest
      setTimeout(() => {
        interaction.startQuest(MAE_PHASE_1_QUEST);
      }, 500);
    } else {
      interaction.advanceDialogue(nextNodeId);
    }
  };

  const handleDialogueNext = () => {
    if (interaction.state.type !== 'dialogue') return;
    
    const currentNode = interaction.state.tree.nodes[interaction.state.currentNodeId];
    if (currentNode && currentNode.next) {
      handleDialogueChoice(currentNode.next);
    }
  };

  // Handle quest answer submission
  const handleQuestSubmit = (answer: string, isCorrect: boolean) => {
    const success = interaction.submitQuestAnswer(answer, isCorrect);
    
    if (success) {
      // Show success dialogue
      setTimeout(() => {
        interaction.closeInteraction();
        interaction.startDialogue(MAE_PHASE_1);
        interaction.advanceDialogue('success.01');
      }, 300);
    } else {
      // Check if out of attempts
      if (interaction.state.type === 'quest') {
        const maxAttempts = interaction.state.quest.maxAttempts || 3;
        if (interaction.state.progress.attempts >= maxAttempts) {
          // Show failure dialogue
          setTimeout(() => {
            interaction.closeInteraction();
            interaction.startDialogue(MAE_PHASE_1);
            interaction.advanceDialogue('failure.01');
          }, 300);
        }
      }
    }
  }; // Empty deps - walk uses setPos callback

  if (!ready) {
    return <View style={s.loading} />;
  }

  // Show map editor
  if (editMode) {
    return (
      <MapEditor
        world={WORLD_1_FARM}
        onSave={(buildings, eventPoints) => {
          console.log('✅ Positions saved! Copy code from console');
        }}
        onClose={() => setEditMode(false)}
      />
    );
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
      {interaction.state.type === 'dialogue' && (
        <DialogueBox
          node={interaction.state.tree.nodes[interaction.state.currentNodeId]}
          onChoice={handleDialogueChoice}
          onNext={handleDialogueNext}
          onSkip={() => interaction.closeInteraction()}
        />
      )}

      {/* Quest System */}
      {interaction.state.type === 'quest' && (
        <QuestUI
          quest={interaction.state.quest}
          onSubmit={handleQuestSubmit}
          onCancel={() => interaction.closeInteraction()}
          attempts={interaction.state.progress.attempts}
          maxAttempts={interaction.state.quest.maxAttempts || 3}
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
    // Width/height set dynamically from useViewportSize
    position: "relative",
    overflow: "hidden",
  },
  loading: {
    flex: 1,
    backgroundColor: "#1F2937",
  },
});
