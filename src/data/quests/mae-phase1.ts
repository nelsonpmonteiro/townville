// Farm World - Phase 1 Quests
// Mae Phase 1: Simple counting (1-10)

import { QuestDefinition } from '../../types/quest';

export const MAE_PHASE_1_QUEST: QuestDefinition = {
  id: 'farm.mae.p1.quest',
  type: 'counting',
  npcId: 'mae',
  phase: 1,
  
  problem: {
    text: 'Quantas galinhas você vê no galinheiro?',
    context: 'Mae precisa saber o total de galinhas para alimentá-las corretamente.',
    image: 'chickens-counting.png', // Optional visual aid
  },
  
  correctAnswer: 7,
  
  hints: [
    'Tente contar uma de cada vez, apontando com o dedo.',
    'Comece de um lado e vá para o outro, sem pular nenhuma.',
    'Lembre-se: 1, 2, 3, 4, 5, 6, 7...',
  ],
  
  successDialogue: 'success.01',
  failureDialogue: 'failure.01',
  
  maxAttempts: 3,
};
