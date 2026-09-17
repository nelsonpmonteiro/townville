// DialogueBox component - displays NPC dialogue with typewriter effect
import React, { useState, useEffect, useRef } from 'react';
import { View, Text, Pressable, StyleSheet, Animated, Platform } from 'react-native';
import { DialogueNode, DialogueChoice } from '../types/dialogue';
import { crossShadow } from '../utils/shadow';

const TILE_SIZE = 48;

interface Props {
  node: DialogueNode;
  onChoice: (nextNodeId: string, isCorrect?: boolean) => void;
  onNext: () => void;
  onSkip: () => void;
}

export default function DialogueBox({ node, onChoice, onNext, onSkip }: Props) {
  const [displayedText, setDisplayedText] = useState('');
  const [isComplete, setIsComplete] = useState(false);
  const [charIndex, setCharIndex] = useState(0);
  const bounceAnim = useRef(new Animated.Value(0)).current;

  // Bounce animation for continue indicator (▼)
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(bounceAnim, {
          toValue: -6,
          duration: 400,
          useNativeDriver: false,
        }),
        Animated.timing(bounceAnim, {
          toValue: 0,
          duration: 400,
          useNativeDriver: false,
        }),
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
      }, 30); // 30ms per character
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

  const handleContinue = () => {
    if (!isComplete) {
      handleSkipTypewriter();
    } else if (node.next) {
      onNext();
    }
  };

  return (
    <View style={styles.container}>
      {/* Dialogue box */}
      <View style={styles.box}>
        {/* Speaker name */}
        <View style={styles.header}>
          <Text style={styles.speaker}>{node.speaker}</Text>
          <Pressable onPress={onSkip} style={styles.skipButton}>
            <Text style={styles.skipText}>Pular ✕</Text>
          </Pressable>
        </View>

        {/* Dialogue text */}
        <Pressable onPress={handleContinue} style={styles.textArea}>
          <Text style={styles.text}>{displayedText}</Text>
          {isComplete && !node.choices && (
            <Animated.Text style={[styles.continueIndicator, { transform: [{ translateY: bounceAnim }] }]}>▼</Animated.Text>
          )}
        </Pressable>

        {/* Choices (for questions) */}
        {isComplete && node.choices && (
          <View style={styles.choicesContainer}>
            {node.choices.map((choice, index) => (
              <Pressable
                key={index}
                style={styles.choiceButton}
                onPress={() => onChoice(choice.next, choice.isCorrect)}
              >
                <Text style={styles.choiceText}>{choice.text}</Text>
              </Pressable>
            ))}
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 40,
    left: 40,
    right: 40,
    zIndex: 100,
    alignItems: 'center',
  },
  box: {
    backgroundColor: 'rgba(0, 0, 0, 0.85)',
    borderRadius: 16,
    padding: 24,
    maxWidth: 800,
    width: '100%',
    borderWidth: 3,
    borderColor: '#4a90e2',
    ...crossShadow('0px 4px 8px rgba(0, 0, 0, 0.5)', {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.5,
      shadowRadius: 8,
    }),
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  speaker: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#4a90e2',
  },
  skipButton: {
    padding: 8,
  },
  skipText: {
    color: '#999',
    fontSize: 14,
  },
  textArea: {
    minHeight: 80,
  },
  text: {
    fontSize: 18,
    lineHeight: 26,
    color: '#fff',
  },
  continueIndicator: {
    fontSize: 24,
    color: '#4a90e2',
    textAlign: 'right',
    marginTop: 8,
  },
  choicesContainer: {
    marginTop: 20,
    gap: 12,
  },
  choiceButton: {
    backgroundColor: '#2c3e50',
    padding: 16,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#4a90e2',
  },
  choiceText: {
    color: '#fff',
    fontSize: 16,
    textAlign: 'center',
  },
});
