import React from "react";
import { View, Text, StyleSheet } from "react-native";

interface GameHeaderProps {
  lives: number;
  maxLives: number;
  score: number;
  streak: number;
  sessionProgress: number; // 0-5
  totalQuests: number; // typically 5
}

export default function GameHeader({
  lives,
  maxLives,
  score,
  streak,
  sessionProgress,
  totalQuests,
}: GameHeaderProps) {
  return (
    <View style={s.container}>
      {/* Lives */}
      <View style={s.section}>
        <Text style={s.label} accessibilityLabel={`${lives} lives remaining`}>
          {Array.from({ length: maxLives }, (_, i) => (
            <Text key={i} style={i < lives ? s.heart : s.heartEmpty}>
              {i < lives ? "❤️" : "🤍"}
            </Text>
          ))}
        </Text>
      </View>

      {/* Score */}
      <View style={s.section}>
        <Text style={s.label} accessibilityLabel={`Score: ${score}`}>
          ⭐ {score}
        </Text>
      </View>

      {/* Streak */}
      <View style={s.section}>
        <Text style={s.label} accessibilityLabel={`Streak: ${streak}`}>
          🔥 {streak}
        </Text>
      </View>

      {/* Session Progress Bar */}
      <View style={s.progressContainer}>
        <Text style={s.progressLabel}>
          Session {sessionProgress}/{totalQuests}
        </Text>
        <View style={s.progressTrack}>
          <View
            style={[
              s.progressBar,
              { width: `${(sessionProgress / totalQuests) * 100}%` },
            ]}
            accessibilityLabel={`Completed ${sessionProgress} of ${totalQuests} quests`}
          />
        </View>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "#7C3AED",
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 3,
    borderBottomColor: "#5B21B6",
  },
  section: {
    flexDirection: "row",
    alignItems: "center",
    marginRight: 16,
  },
  label: {
    fontSize: 18,
    fontWeight: "700",
    color: "#FFFFFF",
  },
  heart: {
    fontSize: 20,
    marginRight: 2,
  },
  heartEmpty: {
    fontSize: 20,
    marginRight: 2,
    opacity: 0.4,
  },
  progressContainer: {
    flex: 1,
    marginLeft: 16,
  },
  progressLabel: {
    fontSize: 12,
    fontWeight: "600",
    color: "#E9D5FF",
    marginBottom: 4,
  },
  progressTrack: {
    height: 8,
    backgroundColor: "#5B21B6",
    borderRadius: 4,
    overflow: "hidden",
  },
  progressBar: {
    height: "100%",
    backgroundColor: "#10B981",
    borderRadius: 4,
  },
});
