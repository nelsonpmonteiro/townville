import React, { useEffect, useState } from "react";
import { View, StyleSheet, Platform } from "react-native";
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
import { MAE_PHASE_1 } from "./src/data/dialogues/mae-phase1";
import { MAE_PHASE_1_QUEST } from "./src/data/quests/mae-phase1";

const KEY = "townville.save.v1";

export default function App() {
  const [save, setSave] = useState<Save>(fresh());
  const [ready, setReady] = useState(false);
  const [pos, setPos] = useState<Point>({ x: 14, y: 9 });
  const [editMode, setEditMode] = useState(false);
  
  // Interaction system
  const interaction = useInteraction();

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

  const walk = (dir: [number, number]) => {
    setPos((p) => {
      const next = { x: p.x + dir[0], y: p.y + dir[1] };
      if (canMoveTo(next, WORLD_1_FARM.collisionMap, [])) {
        // Check for event point collision
        checkEventPointCollision(next);
        return next;
      }
      return p;
    });
  };

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
        const [dx, dy] = dirs[e.key];
        walk(dx, dy);
      }
    };

    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [editMode]);

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
            buildingStates={{}}
          />
        </View>
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
