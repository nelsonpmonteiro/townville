// Dialogue System Types
// Based on HERMES-implementation-instruction.md §7

export type DialogueNodeType = 'text' | 'question' | 'end';

export interface DialogueNode {
  id: string; // e.g., "farm.mae.p1.intro.01"
  type: DialogueNodeType;
  speaker: string; // NPC name
  text: string;
  
  // For 'question' type
  choices?: DialogueChoice[];
  
  // Next node (for 'text' type)
  next?: string;
}

export interface DialogueChoice {
  text: string;
  next: string; // Next dialogue node ID
  isCorrect?: boolean; // For educational questions
}

export interface DialogueTree {
  id: string;
  startNode: string;
  nodes: Record<string, DialogueNode>;
}

// Dialogue state in progress system
export type DialogueState = 'not_started' | 'in_progress' | 'completed';
