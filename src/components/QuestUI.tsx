// QuestUI component - displays math problems and validates answers
import React, { useState } from 'react';
import { View, Text, TextInput, Pressable, StyleSheet } from 'react-native';
import { QuestDefinition } from '../types/quest';

interface Props {
  quest: QuestDefinition;
  onSubmit: (answer: string, isCorrect: boolean) => void;
  onCancel: () => void;
  attempts: number;
  maxAttempts: number;
}

export default function QuestUI({ quest, onSubmit, onCancel, attempts, maxAttempts }: Props) {
  const [answer, setAnswer] = useState('');
  const [showHint, setShowHint] = useState(false);
  const [hintIndex, setHintIndex] = useState(0);

  const handleSubmit = () => {
    if (!answer.trim()) return;

    const isCorrect = answer.trim() === String(quest.correctAnswer);
    onSubmit(answer, isCorrect);
    
    if (!isCorrect) {
      setAnswer('');
      // Show next hint after wrong answer
      if (quest.hints && hintIndex < quest.hints.length - 1) {
        setHintIndex(hintIndex + 1);
        setShowHint(true);
      }
    }
  };

  const remainingAttempts = maxAttempts - attempts;

  return (
    <View style={styles.overlay}>
      <View style={styles.container}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>🎯 Atividade de Matemática</Text>
          <Pressable onPress={onCancel} style={styles.closeButton}>
            <Text style={styles.closeText}>✕</Text>
          </Pressable>
        </View>

        {/* Problem context */}
        {quest.problem.context && (
          <View style={styles.contextBox}>
            <Text style={styles.contextText}>{quest.problem.context}</Text>
          </View>
        )}

        {/* Problem text */}
        <View style={styles.problemBox}>
          <Text style={styles.problemText}>{quest.problem.text}</Text>
        </View>

        {/* Hint (if available) */}
        {showHint && quest.hints && quest.hints[hintIndex] && (
          <View style={styles.hintBox}>
            <Text style={styles.hintLabel}>💡 Dica:</Text>
            <Text style={styles.hintText}>{quest.hints[hintIndex]}</Text>
          </View>
        )}

        {/* Answer input */}
        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>Sua resposta:</Text>
          <TextInput
            style={styles.input}
            value={answer}
            onChangeText={setAnswer}
            placeholder="Digite aqui..."
            placeholderTextColor="#999"
            keyboardType="numeric"
            autoFocus
            onSubmitEditing={handleSubmit}
          />
        </View>

        {/* Attempts remaining */}
        <View style={styles.attemptsBox}>
          <Text style={styles.attemptsText}>
            Tentativas restantes: {remainingAttempts} / {maxAttempts}
          </Text>
          {remainingAttempts <= 1 && (
            <Text style={styles.warningText}>⚠️ Última tentativa!</Text>
          )}
        </View>

        {/* Actions */}
        <View style={styles.actions}>
          {quest.hints && !showHint && (
            <Pressable
              style={[styles.button, styles.hintButton]}
              onPress={() => setShowHint(true)}
            >
              <Text style={styles.buttonText}>💡 Ver Dica</Text>
            </Pressable>
          )}
          <Pressable
            style={[styles.button, styles.submitButton]}
            onPress={handleSubmit}
          >
            <Text style={styles.buttonText}>✓ Enviar</Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 200,
  },
  container: {
    backgroundColor: '#1e293b',
    borderRadius: 16,
    padding: 32,
    maxWidth: 600,
    width: '90%',
    borderWidth: 3,
    borderColor: '#4a90e2',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#4a90e2',
  },
  closeButton: {
    padding: 8,
  },
  closeText: {
    fontSize: 24,
    color: '#999',
  },
  contextBox: {
    backgroundColor: 'rgba(74, 144, 226, 0.1)',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
    borderLeftWidth: 4,
    borderLeftColor: '#4a90e2',
  },
  contextText: {
    fontSize: 16,
    color: '#e2e8f0',
    lineHeight: 24,
  },
  problemBox: {
    backgroundColor: '#334155',
    padding: 20,
    borderRadius: 12,
    marginBottom: 16,
  },
  problemText: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
    lineHeight: 30,
    textAlign: 'center',
  },
  hintBox: {
    backgroundColor: 'rgba(251, 191, 36, 0.1)',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
    borderLeftWidth: 4,
    borderLeftColor: '#fbbf24',
  },
  hintLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#fbbf24',
    marginBottom: 8,
  },
  hintText: {
    fontSize: 16,
    color: '#fef3c7',
    lineHeight: 24,
  },
  inputContainer: {
    marginBottom: 16,
  },
  inputLabel: {
    fontSize: 16,
    color: '#cbd5e1',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#334155',
    borderWidth: 2,
    borderColor: '#4a90e2',
    borderRadius: 8,
    padding: 16,
    fontSize: 18,
    color: '#fff',
  },
  attemptsBox: {
    marginBottom: 24,
  },
  attemptsText: {
    fontSize: 14,
    color: '#94a3b8',
    textAlign: 'center',
  },
  warningText: {
    fontSize: 16,
    color: '#f87171',
    textAlign: 'center',
    marginTop: 8,
    fontWeight: 'bold',
  },
  actions: {
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'center',
  },
  button: {
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 8,
    minWidth: 120,
  },
  hintButton: {
    backgroundColor: '#fbbf24',
  },
  submitButton: {
    backgroundColor: '#10b981',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
  },
});
