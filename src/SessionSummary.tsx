import React from "react";
import { View, Text, Pressable, StyleSheet } from "react-native";

interface SessionSummaryProps {
  questsCompleted: number;
  totalScore: number;
  perfectQuests: number; // quests with no errors
  onPlayAgain: () => void;
}

export default function SessionSummary({
  questsCompleted,
  totalScore,
  perfectQuests,
  onPlayAgain,
}: SessionSummaryProps) {
  const achievements = [];
  
  if (questsCompleted === 5) {
    achievements.push({ icon: "🏆", text: "Session Complete!" });
  }
  if (perfectQuests === 5) {
    achievements.push({ icon: "⭐", text: "Perfect Score!" });
  }
  if (perfectQuests >= 3) {
    achievements.push({ icon: "🔥", text: "Hot Streak!" });
  }

  return (
    <View style={s.container}>
      <View style={s.card}>
        {/* Header */}
        <Text style={s.title}>Great Work!</Text>
        <Text style={s.subtitle}>You've completed your farm session</Text>

        {/* Stats */}
        <View style={s.statsContainer}>
          <View style={s.stat}>
            <Text style={s.statValue}>{questsCompleted}</Text>
            <Text style={s.statLabel}>Quests Done</Text>
          </View>
          <View style={s.stat}>
            <Text style={s.statValue}>{totalScore}</Text>
            <Text style={s.statLabel}>Total Score</Text>
          </View>
          <View style={s.stat}>
            <Text style={s.statValue}>{perfectQuests}</Text>
            <Text style={s.statLabel}>Perfect</Text>
          </View>
        </View>

        {/* Achievements */}
        {achievements.length > 0 && (
          <View style={s.achievements}>
            <Text style={s.achievementsTitle}>Achievements</Text>
            {achievements.map((a, i) => (
              <View key={i} style={s.achievement}>
                <Text style={s.achievementIcon}>{a.icon}</Text>
                <Text style={s.achievementText}>{a.text}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Action Button */}
        <Pressable
          style={s.button}
          onPress={onPlayAgain}
          accessibilityRole="button"
          accessibilityLabel="Play again"
        >
          <Text style={s.buttonText}>🔄 Play Again</Text>
        </Pressable>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0, 0, 0, 0.85)",
    justifyContent: "center",
    alignItems: "center",
    zIndex: 999,
  },
  card: {
    backgroundColor: "#FFFFFF",
    borderRadius: 24,
    padding: 40,
    maxWidth: 500,
    width: "90%",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 15,
  },
  title: {
    fontSize: 36,
    fontWeight: "800",
    color: "#1F2937",
    textAlign: "center",
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    color: "#6B7280",
    textAlign: "center",
    marginBottom: 32,
  },
  statsContainer: {
    flexDirection: "row",
    justifyContent: "space-around",
    marginBottom: 32,
    paddingVertical: 24,
    backgroundColor: "#F9FAFB",
    borderRadius: 16,
  },
  stat: {
    alignItems: "center",
  },
  statValue: {
    fontSize: 40,
    fontWeight: "800",
    color: "#7C3AED",
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 14,
    color: "#6B7280",
    fontWeight: "600",
  },
  achievements: {
    marginBottom: 32,
  },
  achievementsTitle: {
    fontSize: 18,
    fontWeight: "700",
    color: "#1F2937",
    marginBottom: 16,
  },
  achievement: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#FEF3C7",
    padding: 12,
    borderRadius: 12,
    marginBottom: 8,
  },
  achievementIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  achievementText: {
    fontSize: 16,
    fontWeight: "600",
    color: "#92400E",
  },
  button: {
    backgroundColor: "#7C3AED",
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 12,
    alignItems: "center",
    shadowColor: "#7C3AED",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 4,
  },
  buttonText: {
    fontSize: 20,
    fontWeight: "700",
    color: "#FFFFFF",
  },
});
