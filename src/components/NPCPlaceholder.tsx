// NPC avatar placeholder per HERMES-implementation-instruction.md §3.1
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface Props {
  npcId: string;
  npcName: string;
  x: number;
  y: number;
  size?: number;
}

// Simple hash function to generate consistent hue from string
function hashStringToHue(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
    hash = hash & hash; // Convert to 32-bit integer
  }
  return Math.abs(hash % 360);
}

export default function NPCPlaceholder({ npcId, npcName, x, y, size = 40 }: Props) {
  const hue = hashStringToHue(npcId);
  const backgroundColor = `hsl(${hue}, 55%, 60%)`;
  const initial = npcName.charAt(0).toUpperCase();
  
  return (
    <View
      style={[
        styles.container,
        {
          left: x - size / 2,
          top: y - size / 2,
          width: size,
          height: size,
          borderRadius: size / 2,
          backgroundColor,
        },
      ]}
    >
      <Text style={[styles.initial, { fontSize: size * 0.5 }]}>{initial}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 50,
  },
  initial: {
    color: '#fff',
    fontWeight: 'bold',
    textAlign: 'center',
  },
});
