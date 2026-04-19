import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, KeyboardAvoidingView, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import Animated, { FadeInDown } from 'react-native-reanimated';
import Toast from 'react-native-toast-message';
import { ActivationService } from '../../../services/activation.service';
import { colors, sizes } from '../../../constants/helpers';

export default function ActivateScreen() {
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  const formatCode = (value: string) => {
    const cleaned = value.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
    const parts = cleaned.match(/.{1,4}/g) || [];
    return parts.join('-');
  };

  const handleCodeChange = (value: string) => {
    setCode(formatCode(value));
    setResult(null);
  };

  const handleActivate = async () => {
    const cleanCode = code.replace(/-/g, '');
    if (!cleanCode || cleanCode.length < 8) {
      Toast.show({ type: 'error', text1: 'Error', text2: 'Please enter a valid code' });
      return;
    }

    setLoading(true);
    try {
      const response = await ActivationService.activate(cleanCode);
      const activatedExamId =
        typeof response.examId === 'string'
          ? response.examId
          : (response.examId as any)?._id?.toString?.();
      setResult({ success: true, message: response.message || 'Activated successfully!' });
      Toast.show({ type: 'success', text1: 'Activated', text2: response.message || 'Code activated successfully!' });
      setCode('');
      setTimeout(() => {
        if (response.type === 'exam' && activatedExamId) {
          router.replace(`/(tabs)/exams/${activatedExamId}`);
          return;
        }
        if (response.type === 'exam') {
          router.replace('/(tabs)/exams');
          return;
        }
        router.replace('/(tabs)');
      }, 500);
    } catch (error: any) {
      const message = error.response?.data?.message || 'Failed to activate code';
      setResult({ success: false, message: typeof message === 'string' ? message : 'An error occurred' });
      Toast.show({ type: 'error', text1: 'Error', text2: typeof message === 'string' ? message : 'An error occurred' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.flex}>
        <View style={styles.header}>
          <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
            <Ionicons name="arrow-back" size={22} color={colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Activate Code</Text>
          <View style={{ width: 40 }} />
        </View>

        <View style={styles.content}>
          <Animated.View entering={FadeInDown.delay(100).duration(600)} style={styles.iconContainer}>
            <Ionicons name="key" size={56} color={colors.primary} />
          </Animated.View>

          <Animated.View entering={FadeInDown.delay(200).duration(600)}>
            <Text style={styles.title}>Enter Activation Code</Text>
            <Text style={styles.subtitle}>Enter the 12-character code to activate subject or exam</Text>
          </Animated.View>

          <Animated.View entering={FadeInDown.delay(300).duration(600)} style={styles.inputSection}>
            <TextInput
              style={styles.codeInput}
              placeholder="XXXX-XXXX-XXXX"
              placeholderTextColor={colors.textSecondary}
              value={code}
              onChangeText={handleCodeChange}
              autoCapitalize="characters"
              maxLength={14}
              textAlign="center"
              autoCorrect={false}
            />

            <TouchableOpacity
              style={[styles.activateButton, (!code || loading) && styles.activateButtonDisabled]}
              onPress={handleActivate}
              disabled={!code || loading}
            >
              {loading ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <>
                  <Ionicons name="checkmark-circle" size={20} color="#fff" />
                  <Text style={styles.activateButtonText}>Activate</Text>
                </>
              )}
            </TouchableOpacity>
          </Animated.View>

          {result && (
            <Animated.View
              entering={FadeInDown.duration(400)}
              style={[styles.resultCard, result.success ? styles.successCard : styles.errorCard]}
            >
              <Ionicons
                name={result.success ? 'checkmark-circle' : 'alert-circle'}
                size={24}
                color={result.success ? colors.success : colors.danger}
              />
              <Text style={[styles.resultText, { color: result.success ? colors.success : colors.danger }]}>
                {result.message}
              </Text>
            </Animated.View>
          )}
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  flex: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: sizes.lg,
    paddingVertical: sizes.sm,
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
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: sizes.lg,
    paddingBottom: sizes.xxxl * 2,
  },
  iconContainer: {
    width: 100,
    height: 100,
    borderRadius: 28,
    backgroundColor: `${colors.primary}12`,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: sizes.lg,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.textPrimary,
    textAlign: 'center',
    marginBottom: sizes.xs,
  },
  subtitle: {
    fontSize: 14,
    color: colors.textSecondary,
    textAlign: 'center',
    marginBottom: sizes.xl,
    lineHeight: 22,
  },
  inputSection: {
    width: '100%',
    gap: sizes.md,
  },
  codeInput: {
    height: 60,
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    borderWidth: 1.5,
    borderColor: colors.border,
    fontSize: 22,
    fontWeight: '700',
    color: colors.textPrimary,
    letterSpacing: 3,
    paddingHorizontal: sizes.lg,
  },
  activateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 52,
    borderRadius: sizes.sm + 2,
    backgroundColor: colors.primary,
    gap: sizes.sm,
  },
  activateButtonDisabled: {
    backgroundColor: colors.border,
  },
  activateButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
  resultCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: sizes.md,
    borderRadius: sizes.sm + 2,
    marginTop: sizes.lg,
    width: '100%',
    gap: sizes.sm,
  },
  successCard: {
    backgroundColor: `${colors.success}12`,
    borderWidth: 1,
    borderColor: `${colors.success}30`,
  },
  errorCard: {
    backgroundColor: `${colors.danger}12`,
    borderWidth: 1,
    borderColor: `${colors.danger}30`,
  },
  resultText: {
    flex: 1,
    fontSize: 14,
    fontWeight: '600',
    textAlign: 'right',
  },
});
