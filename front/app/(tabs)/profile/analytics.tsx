import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import Animated, { FadeInDown } from 'react-native-reanimated';
import Svg, { Circle } from 'react-native-svg';
import { AnalyticsService } from '../../../services/analytics.service';
import { StudentAnalytics } from '../../../types/analytics';
import { colors, sizes } from '../../../constants/helpers';

export default function AnalyticsScreen() {
  const [analytics, setAnalytics] = useState<StudentAnalytics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        const data = await AnalyticsService.getMyAnalytics();
        setAnalytics(data);
      } catch (error) {
        console.error('Failed to fetch analytics', error);
      } finally {
        setLoading(false);
      }
    };
    fetchAnalytics();
  }, []);

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) return `${hours} hr ${minutes} min`;
    return `${minutes} min`;
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      </SafeAreaView>
    );
  }

  const scoreRadius = 55;
  const scoreCircumference = 2 * Math.PI * scoreRadius;
  const scoreProgress = analytics?.averageScore ? analytics.averageScore / 100 : 0;
  const scoreOffset = scoreCircumference * (1 - scoreProgress);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={22} color={colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>My Analytics</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        {/* Score Circle */}
        <Animated.View entering={FadeInDown.delay(100).duration(600)} style={styles.scoreSection}>
          <View style={styles.scoreCircleContainer}>
            <Svg width={140} height={140} viewBox="0 0 140 140">
              <Circle cx={70} cy={70} r={scoreRadius} stroke={colors.border} strokeWidth={8} fill="none" />
              <Circle
                cx={70}
                cy={70}
                r={scoreRadius}
                stroke={colors.primary}
                strokeWidth={8}
                fill="none"
                strokeDasharray={scoreCircumference}
                strokeDashoffset={scoreOffset}
                strokeLinecap="round"
                transform="rotate(-90 70 70)"
              />
            </Svg>
            <View style={styles.scoreTextContainer}>
              <Text style={styles.scoreValue}>{Math.round(analytics?.averageScore || 0)}%</Text>
              <Text style={styles.scoreLabel}>Average</Text>
            </View>
          </View>
        </Animated.View>

        {/* Stats Grid */}
        <Animated.View entering={FadeInDown.delay(200).duration(600)} style={styles.statsGrid}>
          <View style={styles.statCard}>
            <Ionicons name="time-outline" size={28} color={colors.primary} />
            <Text style={styles.statValue}>{formatDuration(analytics?.totalWatchTimeSeconds || 0)}</Text>
            <Text style={styles.statLabel}>Total Watch Time</Text>
          </View>
          <View style={styles.statCard}>
            <Ionicons name="checkmark-circle-outline" size={28} color={colors.success} />
            <Text style={styles.statValue}>{analytics?.totalExamsCompleted || 0}</Text>
            <Text style={styles.statLabel}>Exams Completed</Text>
          </View>
          <View style={styles.statCard}>
            <Ionicons name="ribbon-outline" size={28} color={colors.warning} />
            <Text style={styles.statValue}>{analytics?.certificates || 0}</Text>
            <Text style={styles.statLabel}>Certificates Earned</Text>
          </View>
        </Animated.View>

        {/* Subject Breakdown */}
        {analytics?.subjectBreakdown && analytics.subjectBreakdown.length > 0 && (
          <Animated.View entering={FadeInDown.delay(300).duration(600)} style={styles.breakdownSection}>
            <Text style={styles.sectionTitle}>Subject Details</Text>
            {analytics.subjectBreakdown.map((item, index) => (
              <View key={index} style={styles.breakdownCard}>
                <View style={styles.breakdownIcon}>
                  <Ionicons name="book" size={20} color={colors.primary} />
                </View>
                <View style={styles.breakdownContent}>
                  <Text style={styles.breakdownTitle}>{item.subjectTitle}</Text>
                  <View style={styles.breakdownMeta}>
                    <Text style={styles.breakdownMetaText}>
                      🕐 {formatDuration(item.watchTimeSeconds)}
                    </Text>
                    <Text style={styles.breakdownMetaText}>
                      📝 {item.examsCompleted} Exams
                    </Text>
                  </View>
                </View>
              </View>
            ))}
          </Animated.View>
        )}
      </ScrollView>
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
  scrollContent: {
    padding: sizes.lg,
    paddingBottom: sizes.xxxl,
  },
  scoreSection: {
    alignItems: 'center',
    marginBottom: sizes.lg,
  },
  scoreCircleContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  scoreTextContainer: {
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
  },
  scoreValue: {
    fontSize: 28,
    fontWeight: 'bold',
    color: colors.primary,
  },
  scoreLabel: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  statsGrid: {
    flexDirection: 'row',
    gap: sizes.sm,
    marginBottom: sizes.lg,
  },
  statCard: {
    flex: 1,
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    alignItems: 'center',
    gap: 6,
    borderWidth: 1,
    borderColor: colors.border,
  },
  statValue: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.textPrimary,
    textAlign: 'center',
  },
  statLabel: {
    fontSize: 11,
    color: colors.textSecondary,
    textAlign: 'center',
  },
  breakdownSection: {
    gap: sizes.sm,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: sizes.xs,
  },
  breakdownCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    borderWidth: 1,
    borderColor: colors.border,
  },
  breakdownIcon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: `${colors.primary}12`,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: sizes.sm + 2,
  },
  breakdownContent: {
    flex: 1,
  },
  breakdownTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: 4,
  },
  breakdownMeta: {
    flexDirection: 'row',
    gap: sizes.md,
  },
  breakdownMetaText: {
    fontSize: 12,
    color: colors.textSecondary,
  },
});
