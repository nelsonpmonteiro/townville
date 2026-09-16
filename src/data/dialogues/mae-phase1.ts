// Farm World - Phase 1 Dialogues
// Mae Phase 1: Introduction to counting chickens

import { DialogueTree } from '../../types/dialogue';

export const MAE_PHASE_1: DialogueTree = {
  id: 'farm.mae.p1',
  startNode: 'intro.01',
  nodes: {
    // Introduction
    'intro.01': {
      id: 'intro.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Oi! Bem-vindo à fazenda! Eu sou a Mae, e cuido das galinhas aqui.',
      next: 'intro.02',
    },
    'intro.02': {
      id: 'intro.02',
      type: 'text',
      speaker: 'Mae',
      text: 'Você pode me ajudar? Preciso contar quantas galinhas estão no galinheiro hoje.',
      next: 'intro.03',
    },
    'intro.03': {
      id: 'intro.03',
      type: 'question',
      speaker: 'Mae',
      text: 'Você sabe contar?',
      choices: [
        { text: 'Sim, eu sei!', next: 'knows.01', isCorrect: true },
        { text: 'Mais ou menos...', next: 'unsure.01' },
        { text: 'Não sei ainda.', next: 'teach.01' },
      ],
    },

    // Player knows how to count
    'knows.01': {
      id: 'knows.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Que ótimo! Então você pode me ajudar agora mesmo!',
      next: 'quest_start',
    },

    // Player is unsure
    'unsure.01': {
      id: 'unsure.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Não se preocupe! Vou te ensinar. Contar é fácil e divertido!',
      next: 'teach.01',
    },

    // Teaching moment
    'teach.01': {
      id: 'teach.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Contar é quando dizemos quantas coisas temos: 1, 2, 3, 4, 5... Vamos praticar!',
      next: 'quest_start',
    },

    // Start quest
    'quest_start': {
      id: 'quest_start',
      type: 'end',
      speaker: 'Mae',
      text: 'Vamos lá! Conte quantas galinhas você vê no galinheiro.',
    },

    // Success response
    'success.01': {
      id: 'success.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Isso mesmo! Você contou certinho! 🎉',
      next: 'success.02',
    },
    'success.02': {
      id: 'success.02',
      type: 'text',
      speaker: 'Mae',
      text: 'Com sua ajuda, posso cuidar melhor das minhas galinhas. Muito obrigada!',
      next: 'complete',
    },
    'complete': {
      id: 'complete',
      type: 'end',
      speaker: 'Mae',
      text: 'Volte sempre que quiser me ajudar!',
    },

    // Failure response
    'failure.01': {
      id: 'failure.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Hmm, não é bem isso... Vamos tentar de novo com calma.',
      next: 'failure.02',
    },
    'failure.02': {
      id: 'failure.02',
      type: 'text',
      speaker: 'Mae',
      text: 'Lembre-se: conte uma galinha de cada vez, devagar.',
      next: 'quest_start',
    },
  },
};
