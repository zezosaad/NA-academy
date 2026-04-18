import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeInDown } from 'react-native-reanimated';
import Svg, { Circle } from 'react-native-svg';
import { colors, sizes } from '../../../constants/helpers';

export default function ExamResultScreen() {
  const { totalQuestions, correctAnswers, scorePercentage, examTitle } = useLocalSearchParams<{
    totalQuestions: string;
    correctAnswers: string;
    scorePercentage: string;
    examTitle: string;
  }>();

  const total = parseInt(totalQuestions || '0');
  const correct = parseInt(correctAnswers || '0');
  const percentage = parseFloat(scorePercentage || '0');
  const passed = percentage >= 70;

  const radius = 70;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - percentage / 100);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Animated.View entering={FadeInDown.delay(100).duration(600)} style={styles.header}>
          <View style={[styles.resultIcon, { backgroundColor: passed ? `${colors.success}15` : `${colors.danger}15` }]}>
            <Ionicons
              name={passed ? 'trophy' : 'refresh-circle'}
              size={48}
              color={passed ? colors.success : colors.danger}
            />
          </View>
          <Text style={styles.title}>{passed ? 'Well done! 🎉' : 'Try again'}</Text>
          {examTitle ? <Text style={styles.examName}>{examTitle}</Text> : null}
        </Animated.View>

        <Animated.View entering={FadeInDown.delay(300).duration(600)} style={styles.circleContainer}>
          <Svg width={180} height={180} viewBox="0 0 180 180">
            <Circle cx={90} cy={90} r={radius} stroke={colors.border} strokeWidth={10} fill="none" />
            <Circle
              cx={90}
              cy={90}
              r={radius}
              stroke={passed ? colors.success : colors.danger}
              strokeWidth={10}
              fill="none"
              strokeDasharray={circumference}
              strokeDashoffset={strokeDashoffset}
              strokeLinecap="round"
              transform="rotate(-90 90 90)"
            />
          </Svg>
          <View style={styles.circleTextContainer}>
            <Text style={[styles.percentageText, { color: passed ? colors.success : colors.danger }]}>
              {Math.round(percentage)}%
            </Text>
          </View>
        </Animated.View>

        <Animated.View entering={FadeInDown.delay(500).duration(600)} style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{total}</Text>
            <Text style={styles.statLabel}>Total Questions</Text>
          </View>
          <View style={[styles.statItem, styles.statBorder]}>
            <Text style={[styles.statValue, { color: colors.success }]}>{correct}</Text>
            <Text style={styles.statLabel}>Correct Answers</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: colors.danger }]}>{total - correct}</Text>
            <Text style={styles.statLabel}>Wrong Answers</Text>
          </View>
        </Animated.View>

        {passed && (
          <Animated.View entering={FadeInDown.delay(700).duration(600)} style={styles.certificateBanner}>
            <Ionicons name="ribbon" size={24} color={colors.warning} />
            <Text style={styles.certificateText}>Congratulations! You received a certificate of completion 🏆</Text>
          </Animated.View>
        )}

        <View style={styles.buttonRow}>
          <TouchableOpacity style={styles.homeButton} onPress={() => router.replace('/(tabs)')}>
            <Ionicons name="home-outline" size={20} color={colors.primary} />
            <Text style={styles.homeButtonText}>Home</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.retryButton} onPress={() => router.back()}>
            <Ionicons name="refresh" size={20} color="#fff" />
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: sizes.lg,
  },
  header: {
    alignItems: 'center',
    marginBottom: sizes.lg,
  },
  resultIcon: {
    width: 88,
    height: 88,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: sizes.md,
  },
  title: {
    fontSize: 26,
    fontWeight: 'bold',
    color: colors.textPrimary,
  },
  examName: {
    fontSize: 14,
    color: colors.textSecondary,
    marginTop: 4,
  },
  circleContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: sizes.xl,
  },
  circleTextContainer: {
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
  },
  percentageText: {
    fontSize: 36,
    fontWeight: 'bold',
  },
  statsRow: {
    flexDirection: 'row',
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: sizes.lg,
    width: '100%',
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: sizes.md,
  },
  statBorder: {
    borderLeftWidth: 1,
    borderRightWidth: 1,
    borderColor: colors.border,
  },
  statValue: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: 2,
  },
  statLabel: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  certificateBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: `${colors.warning}12`,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    gap: sizes.sm,
    marginBottom: sizes.lg,
    width: '100%',
  },
  certificateText: {
    flex: 1,
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
    textAlign: 'right',
  },
  buttonRow: {
    flexDirection: 'row',
    gap: sizes.sm,
    width: '100%',
  },
  homeButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 52,
    borderRadius: sizes.sm + 2,
    backgroundColor: `${colors.primary}12`,
    gap: sizes.xs,
  },
  homeButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.primary,
  },
  retryButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 52,
    borderRadius: sizes.sm + 2,
    backgroundColor: colors.primary,
    gap: sizes.xs,
  },
  retryButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#fff',
  },
});
