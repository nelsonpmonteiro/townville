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
      text: 'Hi! Welcome to the farm! I'm Mae, and I take care of the chickens here.',
      next: 'intro.02',
    },
    'intro.02': {
      id: 'intro.02',
      type: 'text',
      speaker: 'Mae',
      text: 'Can you help me? I need to count how many chickens are in the coop today.',
      next: 'intro.03',
    },
    'intro.03': {
      id: 'intro.03',
      type: 'question',
      speaker: 'Mae',
      text: 'Do you know how to count?',
      choices: [
        { text: 'Yes, I do!', next: 'knows.01', isCorrect: true },
        { text: 'More or less...', next: 'unsure.01' },
        { text: 'Not yet.', next: 'teach.01' },
      ],
    },

    // Player knows how to count
    'knows.01': {
      id: 'knows.01',
      type: 'text',
      speaker: 'Mae',
      text: 'That's great! Then you can help me right now!',
      next: 'quest_start',
    },

    // Player is unsure
    'unsure.01': {
      id: 'unsure.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Don't worry! I\'ll teach you. Counting is easy and fun!',
      next: 'teach.01',
    },

    // Teaching moment
    'teach.01': {
      id: 'teach.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Counting is when we say how many things we have: 1, 2, 3, 4, 5... Let\'s practice!',
      next: 'quest_start',
    },

    // Start quest
    'quest_start': {
      id: 'quest_start',
      type: 'end',
      speaker: 'Mae',
      text: 'Let\'s go! Count how many chickens you see in the coop.',
    },

    // Success response
    'success.01': {
      id: 'success.01',
      type: 'text',
      speaker: 'Mae',
      text: 'That's right! You counted perfectly! 🎉',
      next: 'success.02',
    },
    'success.02': {
      id: 'success.02',
      type: 'text',
      speaker: 'Mae',
      text: 'With your help, I can take better care of my chickens. Thank you so much!',
      next: 'complete',
    },
    'complete': {
      id: 'complete',
      type: 'end',
      speaker: 'Mae',
      text: 'Come back anytime you want to help me!',
    },

    // Failure response
    'failure.01': {
      id: 'failure.01',
      type: 'text',
      speaker: 'Mae',
      text: 'Hmm, that\'s not quite it... Let\'s try again, take your time.',
      next: 'failure.02',
    },
    'failure.02': {
      id: 'failure.02',
      type: 'text',
      speaker: 'Mae',
      text: 'Remember: count one chicken at a time, slowly.',
      next: 'quest_start',
    },
  },
};
