// Interaction System - Handles NPC interactions and dialogue flow
import { useState } from 'react';
import { DialogueTree, DialogueNode } from '../types/dialogue';
import { QuestDefinition, QuestProgress } from '../types/quest';

export type InteractionState = 
  | { type: 'none' }
  | { type: 'dialogue'; tree: DialogueTree; currentNodeId: string }
  | { type: 'quest'; quest: QuestDefinition; progress: QuestProgress };

export function useInteraction() {
  const [state, setState] = useState<InteractionState>({ type: 'none' });

  const startDialogue = (tree: DialogueTree) => {
    setState({
      type: 'dialogue',
      tree,
      currentNodeId: tree.startNode,
    });
  };

  const advanceDialogue = (nextNodeId: string) => {
    if (state.type !== 'dialogue') return;

    const node = state.tree.nodes[nextNodeId];
    if (!node) {
      console.warn(`Node ${nextNodeId} not found in dialogue tree`);
      setState({ type: 'none' });
      return;
    }

    if (node.type === 'end') {
      setState({ type: 'none' });
    } else {
      setState({
        ...state,
        currentNodeId: nextNodeId,
      });
    }
  };

  const startQuest = (quest: QuestDefinition) => {
    setState({
      type: 'quest',
      quest,
      progress: {
        questId: quest.id,
        attempts: 0,
        errors: 0,
        completed: false,
        startedAt: Date.now(),
      },
    });
  };

  const submitQuestAnswer = (answer: string, isCorrect: boolean): boolean => {
    if (state.type !== 'quest') return false;

    const newAttempts = state.progress.attempts + 1;
    const newErrors = isCorrect ? state.progress.errors : state.progress.errors + 1;

    if (isCorrect) {
      setState({
        ...state,
        progress: {
          ...state.progress,
          attempts: newAttempts,
          completed: true,
          completedAt: Date.now(),
        },
      });
      return true;
    } else {
      setState({
        ...state,
        progress: {
          ...state.progress,
          attempts: newAttempts,
          errors: newErrors,
        },
      });
      return false;
    }
  };

  const closeInteraction = () => {
    setState({ type: 'none' });
  };

  return {
    state,
    startDialogue,
    advanceDialogue,
    startQuest,
    submitQuestAnswer,
    closeInteraction,
  };
}
