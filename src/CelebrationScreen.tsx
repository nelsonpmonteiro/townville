import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, Animated } from "react-native";

interface CelebrationScreenProps {
  npcName: string;
  buildingName: string;
  onComplete: () => void;
}

export default function CelebrationScreen({
  npcName,
  buildingName,
  onComplete,
}: CelebrationScreenProps) {
  const [fadeAnim] = useState(new Animated.Value(0));
  const [scaleAnim] = useState(new Animated.Value(0.8));
  const [particles, setParticles] = useState<Array<{ id: number; x: number; y: number }>>([]);

  useEffect(() => {
    // Generate random particles
    const newParticles = Array.from({ length: 20 }, (_, i) => ({
      id: i,
      x: Math.random() * 100 - 50,
      y: Math.random() * 100 - 50,
    }));
    setParticles(newParticles);

    // Entrance animation
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 300,
        useNativeDriver: true,
      }),
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 8,
        tension: 40,
        useNativeDriver: true,
      }),
    ]).start();

    // Auto-dismiss after 1.8 seconds
    const timer = setTimeout(() => {
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 300,
        useNativeDriver: true,
      }).start(({ finished }) => {
        if (finished) onComplete();
      });
    }, 1800);

    return () => clearTimeout(timer);
  }, [fadeAnim, scaleAnim, onComplete]);

  return (
    <Animated.View
      style={[
        s.overlay,
        {
          opacity: fadeAnim,
        },
      ]}
    >
      <Animated.View
        style={[
          s.card,
          {
            transform: [{ scale: scaleAnim }],
          },
        ]}
      >
        {/* Particles */}
        {particles.map((p) => (
          <View
            key={p.id}
            style={[
              s.particle,
              {
                left: `${50 + p.x}%`,
                top: `${50 + p.y}%`,
              },
            ]}
          />
        ))}

        {/* Character reaction */}
        <Text style={s.emoji}>🎉</Text>

        {/* Success message */}
        <Text style={s.title}>Great job!</Text>
        <Text style={s.subtitle}>
          {npcName} is happy!
        </Text>

        {/* Building preview */}
        <View style={s.buildingPreview}>
          <Text style={s.buildingEmoji}>🏠</Text>
          <Text style={s.buildingName}>{buildingName}</Text>
          <Text style={s.buildingStatus}>✨ Unlocked!</Text>
        </View>
      </Animated.View>
    </Animated.View>
  );
}

const s = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0, 0, 0, 0.7)",
    justifyContent: "center",
    alignItems: "center",
    zIndex: 1000,
  },
  card: {
    backgroundColor: "#FFFFFF",
    borderRadius: 24,
    padding: 32,
    alignItems: "center",
    maxWidth: 400,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 16,
    elevation: 10,
  },
  particle: {
    position: "absolute",
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: "#F59E0B",
  },
  emoji: {
    fontSize: 80,
    marginBottom: 16,
  },
  title: {
    fontSize: 32,
    fontWeight: "800",
    color: "#10B981",
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    color: "#6B7280",
    marginBottom: 24,
  },
  buildingPreview: {
    alignItems: "center",
    padding: 16,
    backgroundColor: "#F3F4F6",
    borderRadius: 12,
    width: "100%",
  },
  buildingEmoji: {
    fontSize: 48,
    marginBottom: 8,
  },
  buildingName: {
    fontSize: 20,
    fontWeight: "700",
    color: "#1F2937",
    marginBottom: 4,
  },
  buildingStatus: {
    fontSize: 14,
    color: "#10B981",
    fontWeight: "600",
  },
});
