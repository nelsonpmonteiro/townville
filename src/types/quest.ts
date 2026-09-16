// Quest System Types
// Based on HERMES-implementation-instruction.md §7

export type QuestType = 
  | 'counting'
  | 'compare-groups'
  | 'add-subtract'
  | 'place-value'
  | 'measurement';

export interface QuestDefinition {
  id: string; // e.g., "farm.mae.p1.quest"
  type: QuestType;
  npcId: string;
  phase: 1 | 2 | 3 | 4;
  
  // Problem definition
  problem: {
    text: string; // Question to display
    context?: string; // Story context
    image?: string; // Optional visual aid
  };
  
  // Solution
  correctAnswer: string | number;
  hints?: string[]; // Progressive hints
  
  // Responses
  successDialogue: string; // Dialogue node to play on success
  failureDialogue: string; // Dialogue node to play on error
  
  // Difficulty
  timeLimit?: number; // Seconds (optional)
  maxAttempts?: number; // Default: 3
}

export interface QuestProgress {
  questId: string;
  attempts: number;
  errors: number;
  completed: boolean;
  startedAt: number;
  completedAt?: number;
}

export type QuestState = 'locked' | 'available' | 'active' | 'completed';
