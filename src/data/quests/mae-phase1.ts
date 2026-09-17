// Farm World - Phase 1 Quests
// Mae Phase 1: Simple counting (1-10)

import { QuestDefinition } from '../../types/quest';

export const MAE_PHASE_1_QUEST: QuestDefinition = {
  id: 'farm.mae.p1.quest',
  type: 'counting',
  npcId: 'mae',
  phase: 1,
  
  problem: {
    text: 'How many chickens do you see in the coop?',
    context: 'Mae needs to know the total number of chickens to feed them correctly.',
    image: 'chickens-counting.png', // Optional visual aid
  },
  
  correctAnswer: 7,
  
  hints: [
    'Try counting one at a time, pointing with your finger.',
    'Start from one side and go to the other, without skipping any.',
    'Remember: 1, 2, 3, 4, 5, 6, 7...',
  ],
  
  successDialogue: 'success.01',
  failureDialogue: 'failure.01',
  
  maxAttempts: 3,
};
