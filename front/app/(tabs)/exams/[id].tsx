import React, { useState, useEffect, useRef, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, ScrollView, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeIn } from 'react-native-reanimated';
import { useExams } from '../../../hooks/useExams';
import QuestionCard from '../../../components/QuestionCard';
import ProgressBar from '../../../components/ProgressBar';
import { colors, sizes } from '../../../constants/helpers';

export default function ExamScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { exam, session, loading, startExam, submitExam } = useExams();
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [examStarted, setExamStarted] = useState(false);
  const [timeLeft, setTimeLeft] = useState(0);
  const [questionTimeLeft, setQuestionTimeLeft] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const qTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const questions = exam?.questions || [];
  const currentQuestion = questions[currentQuestionIndex];

  const handleStart = async (isFree: boolean) => {
    try {
      const data = await startExam(id, isFree);
      setExamStarted(true);
      if (data.session.timeLimitMinutes) {
        setTimeLeft(data.session.timeLimitMinutes * 60);
      }
      if (data.exam.questions[0]) {
        setQuestionTimeLeft(data.exam.questions[0].timeLimitSeconds);
      }
    } catch (error: any) {
      const msg = error.response?.data?.message || 'Failed to start exam';
      Alert.alert('Error', typeof msg === 'string' ? msg : 'An error occurred');
    }
  };

  // Global timer
  useEffect(() => {
    if (!examStarted || timeLeft <= 0) return;
    timerRef.current = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          handleAutoSubmit();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [examStarted]);

  // Per-question timer
  useEffect(() => {
    if (!examStarted || !currentQuestion) return;
    setQuestionTimeLeft(currentQuestion.timeLimitSeconds);
    qTimerRef.current = setInterval(() => {
      setQuestionTimeLeft((prev) => {
        if (prev <= 1) {
          handleNextQuestion();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => { if (qTimerRef.current) clearInterval(qTimerRef.current); };
  }, [currentQuestionIndex, examStarted]);

  const handleSelectOption = (label: string) => {
    if (!currentQuestion) return;
    setAnswers((prev) => ({ ...prev, [currentQuestion._id]: label }));
  };

  const handleNextQuestion = () => {
    if (currentQuestionIndex < questions.length - 1) {
      setCurrentQuestionIndex((prev) => prev + 1);
    }
  };

  const handlePrevQuestion = () => {
    if (currentQuestionIndex > 0) {
      setCurrentQuestionIndex((prev) => prev - 1);
    }
  };

  const handleAutoSubmit = useCallback(async () => {
    await handleSubmit();
  }, [answers, session]);

  const handleSubmit = async () => {
    if (!session || submitting) return;
    setSubmitting(true);
    if (timerRef.current) clearInterval(timerRef.current);
    if (qTimerRef.current) clearInterval(qTimerRef.current);

    try {
      const answersArray = Object.entries(answers).map(([questionId, selectedOption]) => ({
        questionId,
        selectedOption,
      }));

      const result = await submitExam({
        examSessionId: session._id,
        answers: answersArray,
      });

      router.replace({
        pathname: '/(tabs)/exams/result',
        params: {
          totalQuestions: result.totalQuestions.toString(),
          correctAnswers: result.correctAnswers.toString(),
          scorePercentage: result.scorePercentage.toString(),
          examTitle: exam?.title || '',
        },
      });
    } catch (error: any) {
      const msg = error.response?.data?.message || 'Failed to submit exam';
      Alert.alert('Error', typeof msg === 'string' ? msg : 'An error occurred');
    } finally {
      setSubmitting(false);
    }
  };

  const formatTimer = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  if (loading && !examStarted) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      </SafeAreaView>
    );
  }

  // Pre-start screen
  if (!examStarted) {
    return (
      <SafeAreaView style={styles.container}>
        <ScrollView contentContainerStyle={styles.preStartContainer}>
          <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
            <Ionicons name="arrow-back" size={22} color={colors.textPrimary} />
          </TouchableOpacity>

          <View style={styles.preStartContent}>
            <View style={styles.examIconContainer}>
              <Ionicons name="document-text" size={56} color={colors.info} />
            </View>
            <Text style={styles.examTitle}>Start Exam</Text>
            <Text style={styles.examSubtitle}>Choose attempt type to start</Text>

            <TouchableOpacity style={styles.startButton} onPress={() => handleStart(false)}>
              <Ionicons name="play" size={20} color="#fff" />
              <Text style={styles.startButtonText}>Start Full Exam</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.freeButton} onPress={() => handleStart(true)}>
              <Ionicons name="gift-outline" size={20} color={colors.success} />
              <Text style={styles.freeButtonText}>Try Free Section</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }

  // Exam in progress
  return (
    <SafeAreaView style={styles.container}>
      {/* Top bar */}
      <View style={styles.topBar}>
        <View style={styles.timerContainer}>
          <Ionicons name="time-outline" size={18} color={timeLeft < 60 ? colors.danger : colors.textSecondary} />
          <Text style={[styles.timerText, timeLeft < 60 && styles.timerDanger]}>
            {formatTimer(timeLeft)}
          </Text>
        </View>
        <Text style={styles.questionCounter}>
          {currentQuestionIndex + 1}/{questions.length}
        </Text>
      </View>

      {/* Progress */}
      <View style={styles.progressContainer}>
        <ProgressBar progress={(currentQuestionIndex + 1) / questions.length} />
      </View>

      {/* Question timer */}
      <View style={styles.questionTimerRow}>
        <Text style={[styles.questionTimerText, questionTimeLeft < 10 && styles.timerDanger]}>
          ⏱ {formatTimer(questionTimeLeft)}
        </Text>
      </View>

      {/* Question */}
      <ScrollView style={styles.questionScroll}>
        {currentQuestion && (
          <Animated.View entering={FadeIn.duration(300)}>
            <QuestionCard
              question={currentQuestion}
              questionNumber={currentQuestionIndex + 1}
              totalQuestions={questions.length}
              selectedOption={answers[currentQuestion._id] || null}
              onSelectOption={handleSelectOption}
            />
          </Animated.View>
        )}
      </ScrollView>

      {/* Bottom navigation */}
      <View style={styles.bottomBar}>
        <TouchableOpacity
          style={[styles.navButton, currentQuestionIndex === 0 && styles.disabledButton]}
          onPress={handlePrevQuestion}
          disabled={currentQuestionIndex === 0}
        >
          <Ionicons name="chevron-back" size={20} color={currentQuestionIndex === 0 ? colors.border : colors.textPrimary} />
          <Text style={[styles.navButtonText, currentQuestionIndex === 0 && styles.disabledText]}>Previous</Text>
        </TouchableOpacity>

        {currentQuestionIndex === questions.length - 1 ? (
          <TouchableOpacity style={styles.submitButton} onPress={handleSubmit} disabled={submitting}>
            {submitting ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.submitButtonText}>Submit Exam</Text>
            )}
          </TouchableOpacity>
        ) : (
          <TouchableOpacity style={styles.nextButton} onPress={handleNextQuestion}>
            <Text style={styles.nextButtonText}>Next</Text>
            <Ionicons name="chevron-forward" size={20} color="#fff" />
          </TouchableOpacity>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  preStartContainer: {
    flexGrow: 1,
    padding: sizes.lg,
  },
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.card,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  preStartContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingBottom: sizes.xxxl * 2,
  },
  examIconContainer: {
    width: 100,
    height: 100,
    borderRadius: 28,
    backgroundColor: `${colors.info}12`,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: sizes.lg,
  },
  examTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.textPrimary,
    marginBottom: sizes.xs,
  },
  examSubtitle: {
    fontSize: 14,
    color: colors.textSecondary,
    marginBottom: sizes.xl,
  },
  startButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    height: 52,
    borderRadius: sizes.sm + 2,
    paddingHorizontal: sizes.xxl,
    gap: sizes.sm,
    width: '100%',
    marginBottom: sizes.sm,
  },
  startButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
  freeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${colors.success}12`,
    height: 52,
    borderRadius: sizes.sm + 2,
    paddingHorizontal: sizes.xxl,
    gap: sizes.sm,
    width: '100%',
    borderWidth: 1.5,
    borderColor: colors.success,
  },
  freeButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.success,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: sizes.lg,
    paddingVertical: sizes.sm,
  },
  timerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  timerText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  timerDanger: {
    color: colors.danger,
  },
  questionCounter: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  progressContainer: {
    paddingHorizontal: sizes.lg,
    marginBottom: sizes.xs,
  },
  questionTimerRow: {
    alignItems: 'center',
    paddingBottom: sizes.xs,
  },
  questionTimerText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  questionScroll: {
    flex: 1,
  },
  bottomBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: sizes.lg,
    backgroundColor: colors.card,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    gap: sizes.sm,
  },
  navButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: sizes.sm,
    paddingHorizontal: sizes.md,
    borderRadius: sizes.sm,
    gap: 4,
  },
  navButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  disabledButton: {
    opacity: 0.4,
  },
  disabledText: {
    color: colors.textSecondary,
  },
  nextButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary,
    paddingVertical: sizes.sm,
    paddingHorizontal: sizes.lg,
    borderRadius: sizes.sm + 2,
    gap: 4,
  },
  nextButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#fff',
  },
  submitButton: {
    backgroundColor: colors.success,
    paddingVertical: sizes.sm,
    paddingHorizontal: sizes.xl,
    borderRadius: sizes.sm + 2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  submitButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#fff',
  },
});
