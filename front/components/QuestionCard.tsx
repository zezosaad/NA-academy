import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, sizes } from '../constants/helpers';
import { Question, QuestionOption } from '../types/exam';

interface QuestionCardProps {
  question: Question;
  questionNumber: number;
  totalQuestions: number;
  selectedOption: string | null;
  onSelectOption: (label: string) => void;
  showCorrectAnswer?: boolean;
}

export default function QuestionCard({
  question,
  questionNumber,
  totalQuestions,
  selectedOption,
  onSelectOption,
  showCorrectAnswer = false,
}: QuestionCardProps) {
  const getOptionStyle = (option: QuestionOption) => {
    if (!selectedOption && !showCorrectAnswer) return styles.option;
    if (showCorrectAnswer && option.label === question.correctOption) {
      return [styles.option, styles.correctOption];
    }
    if (selectedOption === option.label) {
      if (showCorrectAnswer && option.label !== question.correctOption) {
        return [styles.option, styles.wrongOption];
      }
      return [styles.option, styles.selectedOption];
    }
    return styles.option;
  };

  const getOptionTextStyle = (option: QuestionOption) => {
    if (selectedOption === option.label) return [styles.optionText, styles.selectedOptionText];
    if (showCorrectAnswer && option.label === question.correctOption) return [styles.optionText, styles.correctOptionText];
    return styles.optionText;
  };

  return (
    <View style={styles.container}>
      <Text style={styles.counter}>Question {questionNumber} of {totalQuestions}</Text>
      <Text style={styles.questionText}>{question.text}</Text>
      <View style={styles.optionsList}>
        {question.options.map((option, index) => (
          <TouchableOpacity
            key={`${question._id}-${option.label}-${option.text}-${index}`}
            style={getOptionStyle(option)}
            onPress={() => !showCorrectAnswer && onSelectOption(option.label)}
            activeOpacity={showCorrectAnswer ? 1 : 0.7}
          >
            <View style={styles.optionLabel}>
              <Text style={styles.optionLabelText}>{option.label}</Text>
            </View>
            <Text style={getOptionTextStyle(option)}>{option.text}</Text>
            {showCorrectAnswer && option.label === question.correctOption && (
              <Ionicons name="checkmark-circle" size={20} color={colors.success} style={styles.icon} />
            )}
            {showCorrectAnswer && selectedOption === option.label && option.label !== question.correctOption && (
              <Ionicons name="close-circle" size={20} color={colors.danger} style={styles.icon} />
            )}
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: sizes.lg,
  },
  counter: {
    fontSize: 13,
    color: colors.textSecondary,
    marginBottom: sizes.sm,
    textAlign: 'right',
  },
  questionText: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: sizes.lg,
    lineHeight: 28,
    textAlign: 'right',
  },
  optionsList: {
    gap: sizes.sm,
  },
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    borderWidth: 1.5,
    borderColor: colors.border,
  },
  selectedOption: {
    borderColor: colors.primary,
    backgroundColor: `${colors.primary}08`,
  },
  correctOption: {
    borderColor: colors.success,
    backgroundColor: `${colors.success}08`,
  },
  wrongOption: {
    borderColor: colors.danger,
    backgroundColor: `${colors.danger}08`,
  },
  optionLabel: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: `${colors.primary}15`,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: sizes.sm,
  },
  optionLabelText: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.primary,
  },
  optionText: {
    flex: 1,
    fontSize: 15,
    color: colors.textPrimary,
    textAlign: 'right',
  },
  selectedOptionText: {
    color: colors.primary,
    fontWeight: '600',
  },
  correctOptionText: {
    color: colors.success,
    fontWeight: '600',
  },
  icon: {
    marginLeft: sizes.xs,
  },
});
