// DialogueBox component - displays NPC dialogue with typewriter effect.
// Per HERMES-dialogue-spec: centers inside the game VIEWPORT (not the
// window), bottom-anchored, dims the map behind it, and exposes exactly
// one gesture (tap the box) — no other tappable element on screen besides
// the choice buttons that appear once the text has finished typing.
import React, { useState, useEffect, useRef } from 'react';
import { View, Text, Pressable, StyleSheet, Animated } from 'react-native';
import { DialogueNode } from '../types/dialogue';
import { crossShadow } from '../utils/shadow';

const TYPEWRITER_SPEED_MS = 35;

interface Props {
  node: DialogueNode;
  onChoice: (nextNodeId: string, isCorrect?: boolean) => void;
  onNext: () => void;
  onSkip: () => void;
}

// Simple hash → consistent accent color per NPC (same approach as
// NPCPlaceholder), used for the box border, speaker name, and portrait —
// stands in for the world/NPC theme color until real art ships.
function hashStringToHue(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
    hash = hash & hash;
  }
  return Math.abs(hash % 360);
}

export default function DialogueBox({ node, onChoice, onNext }: Props) {
  const [displayedText, setDisplayedText] = useState('');
  const [isComplete, setIsComplete] = useState(false);
  const [charIndex, setCharIndex] = useState(0);
  const bounceAnim = useRef(new Animated.Value(0)).current;

  const accentColor = `hsl(${hashStringToHue(node.speaker)}, 55%, 45%)`;

  // Bounce animation for continue indicator (▼) — only relevant once it's
  // showing, but harmless to keep running.
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(bounceAnim, { toValue: -6, duration: 400, useNativeDriver: false }),
        Animated.timing(bounceAnim, { toValue: 0, duration: 400, useNativeDriver: false }),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, [bounceAnim]);

  // Typewriter effect
  useEffect(() => {
    if (charIndex < node.text.length) {
      const timer = setTimeout(() => {
        setDisplayedText(node.text.slice(0, charIndex + 1));
        setCharIndex(charIndex + 1);
      }, TYPEWRITER_SPEED_MS);
      return () => clearTimeout(timer);
    } else {
      setIsComplete(true);
    }
  }, [charIndex, node.text]);

  // Reset on node change
  useEffect(() => {
    setDisplayedText('');
    setCharIndex(0);
    setIsComplete(false);
  }, [node.id]);

  const handleSkipTypewriter = () => {
    setDisplayedText(node.text);
    setCharIndex(node.text.length);
    setIsComplete(true);
  };

  // The single gesture on the whole dialogue screen: 1st tap while typing
  // reveals the full line; 2nd tap (already complete, no choices) advances.
  // On the final 'end' node, onNext() itself decides whether to advance to
  // another line or exit into the activity (see gameFlow.onAdvance).
  const handleAdvance = () => {
    if (!isComplete) {
      handleSkipTypewriter();
    } else if (!node.choices) {
      onNext();
    }
  };

  return (
    // Overlay: fills the existing viewport container (a child of it, not a
    // new full-screen fixed layer) so it stays centered under letterboxing.
    <View style={styles.overlay} pointerEvents="box-none">
      <View style={styles.dim} pointerEvents="none" />
      <Pressable onPress={handleAdvance} style={[styles.box, { borderColor: accentColor }]}>
        {/* NPC portrait placeholder — fixed 100px, initial-on-color circle */}
        <View style={[styles.portrait, { backgroundColor: accentColor }]}>
          <Text style={styles.portraitInitial}>{node.speaker.charAt(0).toUpperCase()}</Text>
        </View>

        <View style={styles.content}>
          <Text style={[styles.speaker, { color: accentColor }]}>{node.speaker}</Text>
          <Text style={styles.text}>{displayedText}</Text>

          {isComplete && !node.choices && (
            <Animated.Text
              style={[styles.continueIndicator, { transform: [{ translateY: bounceAnim }] }]}
            >
              ▼
            </Animated.Text>
          )}

          {/* Choices only render once the typewriter finishes, so they
              never visually compete with text still being revealed. */}
          {isComplete && node.choices && (
            <View style={styles.choicesContainer}>
              {node.choices.map((choice, index) => (
                <Pressable
                  key={index}
                  style={[styles.choiceButton, { backgroundColor: accentColor }]}
                  onPress={() => onChoice(choice.next, choice.isCorrect)}
                >
                  <Text style={styles.choiceText}>{choice.text}</Text>
                </Pressable>
              ))}
            </View>
          )}
        </View>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    inset: 0,
    alignItems: 'center',
    justifyContent: 'flex-end',
    paddingBottom: 32,
    zIndex: 100,
  },
  dim: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.35)',
  },
  box: {
    width: '88%',
    maxWidth: 640,
    backgroundColor: '#FFF8EC', // warm cream, matches the game palette
    borderRadius: 20,
    borderWidth: 4,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 16,
    ...crossShadow('0px 6px 12px rgba(0, 0, 0, 0.25)', {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 6 },
      shadowOpacity: 0.25,
      shadowRadius: 12,
    }),
  },
  portrait: {
    width: 100,
    height: 100,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  portraitInitial: {
    color: '#fff',
    fontSize: 44,
    fontWeight: 'bold',
  },
  content: {
    flex: 1,
    position: 'relative',
  },
  speaker: {
    fontSize: 20,
    fontWeight: '800',
    marginBottom: 6,
  },
  text: {
    fontSize: 22,
    lineHeight: 30,
    color: '#3A2E1F',
  },
  continueIndicator: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    fontSize: 18,
    color: '#3A2E1F',
  },
  choicesContainer: {
    marginTop: 16,
    gap: 10,
  },
  choiceButton: {
    borderRadius: 14,
    padding: 14,
    minHeight: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  choiceText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '700',
    textAlign: 'center',
  },
});
